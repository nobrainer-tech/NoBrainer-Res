import CoreGraphics
import Observation
import AppKit

@MainActor
@Observable
final class DisplayManager {
    private(set) var displays: [Display] = []
    var activeProfile: Profile?
    var hasProfileDrift: Bool = false

    // Set by NoBrainerResApp after both managers are initialised
    var profileManager: ProfileManager?

    init() {
        refresh()
        registerForDisplayChanges()
    }

    func refresh() {
        var displayIDs = [CGDirectDisplayID](repeating: 0, count: 16)
        var displayCount: UInt32 = 0

        guard CGGetOnlineDisplayList(16, &displayIDs, &displayCount) == .success else {
            displays = []
            return
        }

        let activeIDs = Array(displayIDs.prefix(Int(displayCount)))
        displays = activeIDs.map { buildDisplay(for: $0) }

        autoApplyIfNeeded()
        updateDrift()
    }

    // Called externally (e.g. on app appear) to trigger auto-apply with current display state
    func triggerAutoApply() {
        autoApplyIfNeeded()
        updateDrift()
    }

    func switchMode(displayID: CGDirectDisplayID, mode: DisplayMode) -> Bool {
        guard let cgMode = findCGDisplayMode(displayID: displayID, modeID: mode.id) else {
            return false
        }
        let success = applyMode(displayID: displayID, cgMode: cgMode)
        if success { hasProfileDrift = activeProfile != nil }
        return success
    }

    func switchModeByResolution(displayID: CGDirectDisplayID, width: Int, height: Int, isHiDPI: Bool, refreshRate: Double) -> Bool {
        guard let cgMode = findCGDisplayModeByResolution(displayID: displayID, width: width, height: height, isHiDPI: isHiDPI, refreshRate: refreshRate) else {
            return false
        }
        return applyMode(displayID: displayID, cgMode: cgMode)
    }

    // MARK: - Private

    private func applyMode(displayID: CGDirectDisplayID, cgMode: CGDisplayMode) -> Bool {
        var config: CGDisplayConfigRef?
        guard CGBeginDisplayConfiguration(&config) == .success else { return false }
        CGConfigureDisplayWithDisplayMode(config, displayID, cgMode, nil)
        return CGCompleteDisplayConfiguration(config, .permanently) == .success
    }

    private func buildDisplay(for displayID: CGDirectDisplayID) -> Display {
        let currentCGMode = CGDisplayCopyDisplayMode(displayID)
        let currentModeID = currentCGMode?.ioDisplayModeID

        let options: CFDictionary = [kCGDisplayShowDuplicateLowResolutionModes: kCFBooleanTrue] as CFDictionary
        guard let modeList = CGDisplayCopyAllDisplayModes(displayID, options) as? [CGDisplayMode] else {
            return Display(
                id: displayID,
                name: Display.displayName(for: displayID),
                isBuiltIn: CGDisplayIsBuiltin(displayID) != 0,
                isMain: CGDisplayIsMain(displayID) != 0,
                modes: [],
                currentMode: nil
            )
        }

        let nativeMode = modeList.max(by: { $0.width * $0.height < $1.width * $1.height })

        let allModes = modeList.map { cgMode in
            DisplayMode(
                cgMode: cgMode,
                isCurrent: cgMode.ioDisplayModeID == currentModeID,
                isNative: cgMode.ioDisplayModeID == nativeMode?.ioDisplayModeID
            )
        }

        let deduplicated = DisplayMode.deduplicate(allModes)
        let current = deduplicated.first(where: { $0.isCurrent })

        return Display(
            id: displayID,
            name: Display.displayName(for: displayID),
            isBuiltIn: CGDisplayIsBuiltin(displayID) != 0,
            isMain: CGDisplayIsMain(displayID) != 0,
            modes: deduplicated,
            currentMode: current
        )
    }

    private func findCGDisplayMode(displayID: CGDirectDisplayID, modeID: Int32) -> CGDisplayMode? {
        let options: CFDictionary = [kCGDisplayShowDuplicateLowResolutionModes: kCFBooleanTrue] as CFDictionary
        guard let modeList = CGDisplayCopyAllDisplayModes(displayID, options) as? [CGDisplayMode] else {
            return nil
        }
        return modeList.first(where: { $0.ioDisplayModeID == modeID })
    }

    private func findCGDisplayModeByResolution(displayID: CGDirectDisplayID, width: Int, height: Int, isHiDPI: Bool, refreshRate: Double) -> CGDisplayMode? {
        let options: CFDictionary = [kCGDisplayShowDuplicateLowResolutionModes: kCFBooleanTrue] as CFDictionary
        guard let modeList = CGDisplayCopyAllDisplayModes(displayID, options) as? [CGDisplayMode] else {
            return nil
        }
        return modeList.first { mode in
            mode.width == width &&
            mode.height == height &&
            (mode.pixelWidth > mode.width) == isHiDPI &&
            Int(mode.refreshRate) == Int(refreshRate)
        }
    }

    private func autoApplyIfNeeded() {
        guard let profileManager else { return }
        guard let profile = profileManager.profiles.first(where: { $0.autoApply }) else { return }

        let hasExternals = displays.contains(where: { !$0.isBuiltIn })
        guard hasExternals else { return }

        // Avoid re-applying if already active and no drift
        if activeProfile?.id == profile.id { return }

        let success = profileManager.apply(profile: profile, using: self)
        if success {
            activeProfile = profile
            hasProfileDrift = false
        }
    }

    private func updateDrift() {
        guard let profile = activeProfile else {
            hasProfileDrift = false
            return
        }

        for config in profile.displayConfigurations {
            if config.isBuiltIn {
                guard let display = displays.first(where: { $0.isBuiltIn }),
                      let current = display.currentMode else {
                    hasProfileDrift = true
                    return
                }
                if !modesMatch(current: current, config: config) {
                    hasProfileDrift = true
                    return
                }
            } else {
                for display in displays where !display.isBuiltIn {
                    guard let current = display.currentMode else {
                        hasProfileDrift = true
                        return
                    }
                    if !modesMatch(current: current, config: config) {
                        hasProfileDrift = true
                        return
                    }
                }
            }
        }

        hasProfileDrift = false
    }

    private func modesMatch(current: DisplayMode, config: Profile.DisplayConfiguration) -> Bool {
        current.width == config.width &&
        current.height == config.height &&
        current.isHiDPI == config.isHiDPI &&
        Int(current.refreshRate) == Int(config.refreshRate)
    }

    private func registerForDisplayChanges() {
        CGDisplayRegisterReconfigurationCallback({ _, _, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: .displayReconfigured, object: nil)
            }
        }, nil)

        NotificationCenter.default.addObserver(
            forName: .displayReconfigured,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }
}

extension Notification.Name {
    static let displayReconfigured = Notification.Name("displayReconfigured")
}
