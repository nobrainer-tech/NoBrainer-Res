import Foundation
import Observation

@MainActor
@Observable
final class ProfileManager {
    private(set) var profiles: [Profile] = []

    private let fileURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent(Constants.bundleIdentifier)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("profiles.json")
    }()

    init() {
        load()
    }

    func save(profile: Profile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
        } else {
            profiles.append(profile)
        }
        persist()
    }

    func delete(profile: Profile) {
        profiles.removeAll(where: { $0.id == profile.id })
        persist()
    }

    func createFromCurrentState(name: String, displayManager: DisplayManager) -> Profile {
        let configs = displayManager.displays.compactMap { display -> Profile.DisplayConfiguration? in
            guard let current = display.currentMode else { return nil }
            return Profile.DisplayConfiguration(
                displayID: display.id,
                modeID: current.id,
                width: current.width,
                height: current.height,
                isHiDPI: current.isHiDPI,
                refreshRate: current.refreshRate
            )
        }

        let profile = Profile(name: name, displayConfigurations: configs)
        save(profile: profile)
        return profile
    }

    func apply(profile: Profile, using displayManager: DisplayManager) -> Bool {
        var allSucceeded = true
        for config in profile.displayConfigurations {
            let mode = DisplayMode(
                id: config.modeID,
                width: config.width,
                height: config.height,
                refreshRate: config.refreshRate,
                isHiDPI: config.isHiDPI,
                bitDepth: 32,
                isNative: false,
                isCurrent: false
            )

            if !displayManager.switchMode(displayID: config.displayID, mode: mode) {
                allSucceeded = false
            }
        }
        return allSucceeded
    }

    // MARK: - Persistence

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            profiles = try JSONDecoder().decode([Profile].self, from: data)
        } catch {
            profiles = []
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(profiles)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Silent fail - profiles are non-critical
        }
    }
}
