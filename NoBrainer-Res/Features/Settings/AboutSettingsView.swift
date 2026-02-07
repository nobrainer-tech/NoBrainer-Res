import SwiftUI

struct AboutSettingsView: View {
    var body: some View {
        Form {
            Section("About") {
                LabeledContent("Version", value: appVersion)
                LabeledContent("Build", value: buildNumber)
            }

            Section {
                VStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.pink)

                    Text("NoBrainer Res is free and always will be.")
                        .font(.callout)
                        .multilineTextAlignment(.center)

                    Text("If you find it useful, consider supporting development with a pay-what-you-want contribution.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 16) {
                        Button {
                            NSWorkspace.shared.open(Constants.supportURL)
                        } label: {
                            Text("Support the Dev")
                                .fontWeight(.medium)
                        }
                        .controlSize(.large)

                        Button {
                            NSWorkspace.shared.open(Constants.websiteURL)
                        } label: {
                            Text("nobrainer.tech")
                        }
                        .controlSize(.large)
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .formStyle(.grouped)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
