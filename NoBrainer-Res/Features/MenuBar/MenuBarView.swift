import SwiftUI

struct MenuBarView: View {
    @Environment(DisplayManager.self) private var displayManager
    @Environment(ProfileManager.self) private var profileManager
    @State private var showNewProfileSheet = false
    @State private var newProfileName = ""

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
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 400)

            if !displayManager.displays.isEmpty {
                saveProfileButton
            }

            QuickActionsView(
                profiles: profileManager.profiles,
                onApplyProfile: { profile in
                    _ = profileManager.apply(profile: profile, using: displayManager)
                }
            )
        }
        .padding(12)
        .frame(width: 340)
        .sheet(isPresented: $showNewProfileSheet) {
            newProfileSheet
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
            showNewProfileSheet = true
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

    private var newProfileSheet: some View {
        VStack(spacing: 16) {
            Text("New Profile")
                .font(.headline)

            TextField("Profile Name", text: $newProfileName)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Cancel") {
                    newProfileName = ""
                    showNewProfileSheet = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save") {
                    _ = profileManager.createFromCurrentState(
                        name: newProfileName,
                        displayManager: displayManager
                    )
                    newProfileName = ""
                    showNewProfileSheet = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newProfileName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 280)
    }
}
