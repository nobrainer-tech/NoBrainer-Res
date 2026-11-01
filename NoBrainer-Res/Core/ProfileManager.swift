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

        // Capture only one external config - apply() will apply it to all external displays
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

    /// Applies all of the profile's display configurations together, or none of them.
    /// Manual applications ask the user to keep the new modes and revert otherwise.
    func apply(profile: Profile, using displayManager: DisplayManager, confirm: Bool = true) -> Bool {
        displayManager.apply(profile: profile, confirm: confirm)
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

        // Sample profile for macOS + Viture XR glasses setup.
        // autoApply is disabled so it does not silently change modes on other hardware.
        let defaultProfile = Profile(
            name: "macOS+Viture",
            displayConfigurations: [
                Profile.DisplayConfiguration(isBuiltIn: true, width: 3024, height: 1964, isHiDPI: true, refreshRate: 120),
                Profile.DisplayConfiguration(isBuiltIn: false, width: 2560, height: 1600, isHiDPI: true, refreshRate: 60)
            ],
            autoApply: false
        )

        save(profile: defaultProfile)
    }
}
