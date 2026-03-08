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
        seedDefaultProfileIfNeeded()
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
        var configs: [Profile.DisplayConfiguration] = []

        if let builtIn = displayManager.displays.first(where: { $0.isBuiltIn }),
           let current = builtIn.currentMode {
            configs.append(Profile.DisplayConfiguration(
                isBuiltIn: true,
                width: current.width,
                height: current.height,
                isHiDPI: current.isHiDPI,
                refreshRate: current.refreshRate
            ))
        }

        if let external = displayManager.displays.first(where: { !$0.isBuiltIn }),
           let current = external.currentMode {
            configs.append(Profile.DisplayConfiguration(
                isBuiltIn: false,
                width: current.width,
                height: current.height,
                isHiDPI: current.isHiDPI,
                refreshRate: current.refreshRate
            ))
        }

        let profile = Profile(name: name, displayConfigurations: configs)
        save(profile: profile)
        return profile
    }

    func apply(profile: Profile, using displayManager: DisplayManager) -> Bool {
        var allSucceeded = true

        for config in profile.displayConfigurations {
            if config.isBuiltIn {
                if let display = displayManager.displays.first(where: { $0.isBuiltIn }) {
                    if !displayManager.switchModeByResolution(
                        displayID: display.id,
                        width: config.width,
                        height: config.height,
                        isHiDPI: config.isHiDPI,
                        refreshRate: config.refreshRate
                    ) {
                        allSucceeded = false
                    }
                }
            } else {
                for display in displayManager.displays where !display.isBuiltIn {
                    if !displayManager.switchModeByResolution(
                        displayID: display.id,
                        width: config.width,
                        height: config.height,
                        isHiDPI: config.isHiDPI,
                        refreshRate: config.refreshRate
                    ) {
                        allSucceeded = false
                    }
                }
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

    private func seedDefaultProfileIfNeeded() {
        guard profiles.isEmpty else { return }

        let defaultProfile = Profile(
            name: "macOS+Viture",
            displayConfigurations: [
                Profile.DisplayConfiguration(isBuiltIn: true, width: 3024, height: 1964, isHiDPI: true, refreshRate: 120),
                Profile.DisplayConfiguration(isBuiltIn: false, width: 2560, height: 1600, isHiDPI: true, refreshRate: 60)
            ],
            autoApply: true
        )

        save(profile: defaultProfile)
    }
}
