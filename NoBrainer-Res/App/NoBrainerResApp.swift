import SwiftUI

@main
struct NoBrainerResApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var displayManager = DisplayManager()
    @State private var profileManager = ProfileManager()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(displayManager)
                .environment(profileManager)
        } label: {
            Image(systemName: "display")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(displayManager)
                .environment(profileManager)
        }
    }
}
