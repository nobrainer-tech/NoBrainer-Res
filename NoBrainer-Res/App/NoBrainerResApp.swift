import SwiftUI

@main
struct NoBrainerResApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var displayManager: DisplayManager
    @State private var profileManager: ProfileManager
    @State private var virtualDisplayManager = VirtualDisplayManager()

    init() {
        let dm = DisplayManager()
        let pm = ProfileManager()
        dm.profileManager = pm
        _displayManager = State(initialValue: dm)
        _profileManager = State(initialValue: pm)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(displayManager)
                .environment(profileManager)
                .environment(virtualDisplayManager)
                .onAppear {
                    displayManager.triggerAutoApply()
                }
        } label: {
            Image(systemName: "display")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(displayManager)
                .environment(profileManager)
                .environment(virtualDisplayManager)
        }
    }
}
