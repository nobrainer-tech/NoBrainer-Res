import SwiftUI
import KeyboardShortcuts

struct ShortcutsSettingsView: View {
    var body: some View {
        Form {
            Section("Resolution Shortcuts") {
                KeyboardShortcuts.Recorder("Next Resolution", name: .nextResolution)
                KeyboardShortcuts.Recorder("Previous Resolution", name: .previousResolution)
            }

            Section("Profiles") {
                KeyboardShortcuts.Recorder("Apply Profile 1", name: .applyProfile1)
                KeyboardShortcuts.Recorder("Apply Profile 2", name: .applyProfile2)
                KeyboardShortcuts.Recorder("Apply Profile 3", name: .applyProfile3)
            }
        }
        .formStyle(.grouped)
    }
}
