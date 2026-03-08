import SwiftUI

struct QuickActionsView: View {
    @Environment(\.openSettings) private var openSettings
    @Environment(DisplayManager.self) private var displayManager
    @Environment(ProfileManager.self) private var profileManager

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.vertical, 4)

            if !profileManager.profiles.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Profiles")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 2)

                    ForEach(profileManager.profiles) { profile in
                        Button {
                            let success = profileManager.apply(profile: profile, using: displayManager)
                            if success { displayManager.markProfileApplied(profile) }
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.3.group")
                                    .font(.system(size: 11))
                                Text(profile.name)
                                if profile.autoApply {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.yellow)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    if displayManager.hasProfileDrift, let active = displayManager.activeProfile {
                        Button {
                            let success = profileManager.apply(profile: active, using: displayManager)
                            if success { displayManager.markProfileApplied(active) }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 11))
                                Text("Restore \"\(active.name)\"")
                                Spacer()
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.orange)
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
