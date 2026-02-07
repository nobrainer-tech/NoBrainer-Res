import CoreGraphics
import Observation
import AppKit

@MainActor
@Observable
final class DisplayManager {
    private(set) var displays: [Display] = []

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
    }

    func switchMode(displayID: CGDirectDisplayID, mode: DisplayMode) -> Bool {
        guard let cgMode = findCGDisplayMode(displayID: displayID, modeID: mode.id) else {
            return false
        }

        var config: CGDisplayConfigRef?
        guard CGBeginDisplayConfiguration(&config) == .success else { return false }

        CGConfigureDisplayWithDisplayMode(config, displayID, cgMode, nil)

        let result = CGCompleteDisplayConfiguration(config, .permanently)
        return result == .success
    }

    // MARK: - Private

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
