import Foundation
import CoreGraphics

// MARK: - Paths

let appSupportDir: URL = {
    let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let dir  = base.appendingPathComponent("NoBrainer Res")
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
}()

let configURL = appSupportDir.appendingPathComponent("virtual-displays.json")
let pidURL    = appSupportDir.appendingPathComponent("daemon.pid")

// MARK: - Write PID

try? "\(ProcessInfo.processInfo.processIdentifier)"
    .write(to: pidURL, atomically: true, encoding: .utf8)

// MARK: - Display state (name → retained CGVirtualDisplay object)

var activeDisplays: [String: AnyObject] = [:]

// MARK: - Resolution Guard
// Maps CGDirectDisplayID → target (width, height).
// Any mode change away from target is immediately reversed.

var resolutionGuard: [CGDirectDisplayID: (w: Int, h: Int)] = [:]
var guardRegistered = false

/// Read the CGDirectDisplayID from a CGVirtualDisplay object via objc_msgSend.
func getVirtualDisplayID(_ display: AnyObject) -> CGDirectDisplayID? {
    typealias GetIDFn = @convention(c) (AnyObject, Selector) -> CGDirectDisplayID
    let fn = unsafeBitCast(
        dlsym(dlopen(nil, RTLD_LAZY), "objc_msgSend"),
        to: GetIDFn.self
    )
    let id = fn(display, Selector("displayID"))
    return id > 0 ? id : nil
}

/// Force a virtual display back to its target resolution.
func forceMode(displayID: CGDirectDisplayID, w: Int, h: Int) {
    guard let allModes = CGDisplayCopyAllDisplayModes(displayID, nil) as? [CGDisplayMode],
          let target   = allModes.first(where: { $0.width == w && $0.height == h })
    else {
        print("[VDKeeper] no mode \(w)×\(h) found on display \(displayID)")
        return
    }
    var cfg: CGDisplayConfigRef?
    guard CGBeginDisplayConfiguration(&cfg) == .success else { return }
    CGConfigureDisplayWithDisplayMode(cfg, displayID, target, nil)
    let result = CGCompleteDisplayConfiguration(cfg, .permanently)
    print("[VDKeeper] forced \(w)×\(h) on display \(displayID): \(result == .success ? "OK" : "ERR \(result.rawValue)")")
}

/// Register the CG reconfiguration callback exactly once.
/// Fires whenever any display's mode changes; we only act on guarded virtual displays.
func registerResolutionGuardOnce() {
    guard !guardRegistered else { return }
    guardRegistered = true

    CGDisplayRegisterReconfigurationCallback({ displayID, flags, _ in
        // Only react to actual mode/resolution changes, not connect/disconnect events.
        guard flags.contains(.setModeFlag) else { return }
        guard let target = resolutionGuard[displayID] else { return }

        // Read current mode — if it already matches target, nothing to do.
        guard let current = CGDisplayCopyDisplayMode(displayID) else { return }
        guard current.width != target.w || current.height != target.h else { return }

        print("[VDKeeper] resolution drift on \(displayID): \(current.width)×\(current.height) → restoring \(target.w)×\(target.h)")

        // Must NOT call CGBeginDisplayConfiguration from inside the callback.
        // Dispatch with a short delay so the current transaction fully completes first.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            forceMode(displayID: displayID, w: target.w, h: target.h)
        }
    }, nil)

    print("[VDKeeper] resolution guard registered")
}

/// After a virtual display is created, discover its CGDirectDisplayID and register it
/// in resolutionGuard. We retry a few times because the OS needs ~1s to assign the ID.
func registerGuard(for display: AnyObject, w: Int, h: Int, attempt: Int = 0) {
    if let dID = getVirtualDisplayID(display), dID > 0 {
        resolutionGuard[dID] = (w: w, h: h)
        registerResolutionGuardOnce()
        print("[VDKeeper] guarding display \(dID) at \(w)×\(h)")
    } else if attempt < 5 {
        // Retry — displayID may not be assigned yet immediately after creation.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            registerGuard(for: display, w: w, h: h, attempt: attempt + 1)
        }
    } else {
        print("[VDKeeper] WARNING: could not obtain displayID for \(w)×\(h) virtual display — resolution guard inactive")
    }
}

// MARK: - Sync

/// Retry interval when virtual display creation fails (e.g. another process holds the slot).
/// After a reboot, the daemon may start before Screen Sharing and succeed on first try.
/// If Screen Sharing is already active, retry until the slot is free.
var syncRetryWorkItem: DispatchWorkItem?

func syncDisplays() {
    guard let data = try? Data(contentsOf: configURL),
          let configs = try? JSONDecoder().decode([VDConfig].self, from: data)
    else { return }

    let wanted      = configs.filter(\.connectOnStartup)
    let wantedNames = Set(wanted.map(\.name))
    let haveNames   = Set(activeDisplays.keys)

    // Remove displays no longer configured
    for name in haveNames where !wantedNames.contains(name) {
        // Clean up guard entry for the removed display.
        if let obj = activeDisplays[name], let dID = getVirtualDisplayID(obj) {
            resolutionGuard.removeValue(forKey: dID)
        }
        activeDisplays.removeValue(forKey: name)
        print("[VDKeeper] removed: \(name)")
    }

    // Create newly added displays
    var anyFailed = false
    for config in wanted where !haveNames.contains(config.name) {
        if let obj = createVirtualDisplay(config: config) {
            activeDisplays[config.name] = obj
            print("[VDKeeper] created: \(config.name) \(config.width)×\(config.height)")
            // Register the resolution guard after a brief delay for the ID to stabilise.
            registerGuard(for: obj, w: config.width, h: config.height)
        } else {
            print("[VDKeeper] FAILED: \(config.name) — will retry in 30s")
            anyFailed = true
        }
    }

    // Schedule a retry if any display failed to create.
    // This handles the case where another process (e.g. Screen Sharing) currently holds
    // the virtual display slot. The slot may free up when Screen Sharing disconnects.
    syncRetryWorkItem?.cancel()
    if anyFailed {
        let item = DispatchWorkItem { syncDisplays() }
        syncRetryWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 30, execute: item)
    }
}

// MARK: - File watcher (re-opens on delete/rename so atomic writes work)

func watchConfigFile() {
    func open() {
        let fd = Foundation.open(configURL.path, O_EVTONLY)
        if fd < 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { open() }
            return
        }
        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename, .attrib],
            queue: .main
        )
        src.setEventHandler {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                syncDisplays()
                // If file was replaced, re-open a new watcher
                let flags = src.data
                if flags.contains(.delete) || flags.contains(.rename) {
                    src.cancel()
                    open()
                }
            }
        }
        src.setCancelHandler { close(fd) }
        src.resume()
    }
    open()
}

// MARK: - SIGUSR1 → immediate reload

signal(SIGUSR1, SIG_IGN)
let sigSrc = DispatchSource.makeSignalSource(signal: SIGUSR1, queue: .main)
sigSrc.setEventHandler { syncDisplays() }
sigSrc.resume()

// MARK: - Boot

print("[VDKeeper] starting")
syncDisplays()
watchConfigFile()
print("[VDKeeper] running PID \(ProcessInfo.processInfo.processIdentifier)")
RunLoop.main.run()
