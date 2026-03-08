import SwiftUI

struct MenuBarView: View {
    @Environment(DisplayManager.self) private var displayManager
    @Environment(ProfileManager.self) private var profileManager
    @Environment(VirtualDisplayManager.self) private var virtualDisplayManager
    @State private var showProfileEditor = false

    var body: some View {
        VStack(spacing: 8) {
            header

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(displayManager.displays) { display in
                        DisplaySectionView(display: display) { mode in
                            _ = displayManager.switchMode(displayID: display.id, mode: mode)
                        }
                    }

                    if !virtualDisplayManager.virtualDisplays.isEmpty {
                        VirtualDisplaySectionView()
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 400)

            if !displayManager.displays.isEmpty {
                saveProfileButton
            }

            QuickActionsView()
        }
        .padding(12)
        .frame(width: 340)
        .sheet(isPresented: $showProfileEditor) {
            ProfileEditorView {
                showProfileEditor = false
            }
            .environment(displayManager)
            .environment(profileManager)
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack {
            Text("NoBrainer Res")
                .font(.headline)
            Spacer()
            Button {
                displayManager.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)
            .help("Refresh displays")
        }
        .padding(.horizontal, 4)
    }

    private var saveProfileButton: some View {
        Button {
            showProfileEditor = true
        } label: {
            HStack {
                Image(systemName: "plus.circle")
                    .font(.system(size: 11))
                Text("Save Current as Profile")
                    .font(.caption)
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
    }
}
