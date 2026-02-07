import SwiftUI

struct QuickActionsView: View {
    @Environment(\.openSettings) private var openSettings
    let profiles: [Profile]
    let onApplyProfile: (Profile) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.vertical, 4)

            if !profiles.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Profiles")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 2)

                    ForEach(profiles) { profile in
                        Button {
                            onApplyProfile(profile)
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.3.group")
                                    .font(.system(size: 11))
                                Text(profile.name)
                                Spacer()
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    Divider()
                        .padding(.vertical, 4)
                }
            }

            HStack(spacing: 12) {
                Button {
                    openSettings()
                } label: {
                    Label("Settings...", systemImage: "gear")
                        .font(.caption)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    NSWorkspace.shared.open(Constants.supportURL)
                } label: {
                    Text("Support the Dev")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.pink)
                }
                .buttonStyle(.plain)

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Label("Quit", systemImage: "power")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
    }
}
