import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let nextResolution = Self("nextResolution")
    static let previousResolution = Self("previousResolution")
    static let applyProfile1 = Self("applyProfile1")
    static let applyProfile2 = Self("applyProfile2")
    static let applyProfile3 = Self("applyProfile3")
}

@MainActor
final class KeyboardShortcutManager {
    private let displayManager: DisplayManager
    private let profileManager: ProfileManager

    init(displayManager: DisplayManager, profileManager: ProfileManager) {
        self.displayManager = displayManager
        self.profileManager = profileManager
        setupHandlers()
    }

    private func setupHandlers() {
        KeyboardShortcuts.onKeyUp(for: .nextResolution) { [weak self] in
            Task { @MainActor in
                self?.cycleResolution(forward: true)
            }
        }

        KeyboardShortcuts.onKeyUp(for: .previousResolution) { [weak self] in
            Task { @MainActor in
                self?.cycleResolution(forward: false)
            }
        }

        KeyboardShortcuts.onKeyUp(for: .applyProfile1) { [weak self] in
            Task { @MainActor in
                self?.applyProfile(at: 0)
            }
        }

        KeyboardShortcuts.onKeyUp(for: .applyProfile2) { [weak self] in
            Task { @MainActor in
                self?.applyProfile(at: 1)
            }
        }

        KeyboardShortcuts.onKeyUp(for: .applyProfile3) { [weak self] in
            Task { @MainActor in
                self?.applyProfile(at: 2)
            }
        }
    }

    private func cycleResolution(forward: Bool) {
        guard let display = displayManager.displays.first,
              let currentMode = display.currentMode else { return }

        let modes = display.sortedModes
        guard let currentIndex = modes.firstIndex(where: { $0.id == currentMode.id }) else { return }

        let nextIndex: Int
        if forward {
            nextIndex = (currentIndex + 1) % modes.count
        } else {
            nextIndex = (currentIndex - 1 + modes.count) % modes.count
        }

        _ = displayManager.switchMode(displayID: display.id, mode: modes[nextIndex])
    }

    private func applyProfile(at index: Int) {
        guard index < profileManager.profiles.count else { return }
        _ = profileManager.apply(profile: profileManager.profiles[index], using: displayManager)
    }
}
