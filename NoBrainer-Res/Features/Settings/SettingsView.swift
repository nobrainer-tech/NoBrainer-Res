import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            ShortcutsSettingsView()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }

            DisplayPlacerSettingsView()
                .tabItem {
                    Label("Advanced", systemImage: "rectangle.badge.plus")
                }

            VirtualDisplaySettingsView()
                .tabItem {
                    Label("Virtual", systemImage: "square.dashed")
                }

            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 520)
    }
}
