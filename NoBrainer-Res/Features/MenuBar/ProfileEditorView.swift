import SwiftUI

struct ProfileEditorView: View {
    @Environment(DisplayManager.self) private var displayManager
    @Environment(ProfileManager.self) private var profileManager

    let onDismiss: () -> Void

    @State private var name: String = ""
    @State private var autoApply: Bool = false
    @State private var builtInMode: DisplayMode?
    @State private var externalMode: DisplayMode?

    private var builtInDisplay: Display? {
        displayManager.displays.first(where: { $0.isBuiltIn })
    }

    private var externalDisplay: Display? {
        displayManager.displays.first(where: { !$0.isBuiltIn })
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        (builtInMode != nil || externalMode != nil)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Profile")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Profile Name")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("e.g. Desk Setup", text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            Toggle("Auto-apply when external displays connected", isOn: $autoApply)
                .toggleStyle(.checkbox)
                .font(.callout)

            Divider()

            builtInSection
            externalSection
        }
        .padding(20)
        .frame(width: 320)
        .onAppear { prefillFromCurrentState() }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button("Cancel") { onDismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save Profile") { saveProfile() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canSave)
            }
            .padding(20)
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var builtInSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Built-in Display")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let display = builtInDisplay {
                Picker("Resolution", selection: $builtInMode) {
                    ForEach(display.sortedModes) { mode in
                        Text(mode.summary).tag(Optional(mode))
                    }
                }
                .labelsHidden()
            } else {
                Text("No built-in display detected")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    @ViewBuilder
    private var externalSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("External Displays (all)")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let display = externalDisplay {
                Picker("Resolution", selection: $externalMode) {
                    Text("None").tag(Optional<DisplayMode>.none)
                    ForEach(display.sortedModes) { mode in
                        Text(mode.summary).tag(Optional(mode))
                    }
                }
                .labelsHidden()
            } else {
                Text("No external display connected")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Actions

    private func prefillFromCurrentState() {
        builtInMode = builtInDisplay?.currentMode
        externalMode = externalDisplay?.currentMode
    }

    private func saveProfile() {
        var configs: [Profile.DisplayConfiguration] = []

        if let mode = builtInMode {
            configs.append(Profile.DisplayConfiguration(
                isBuiltIn: true,
                width: mode.width,
                height: mode.height,
                isHiDPI: mode.isHiDPI,
                refreshRate: mode.refreshRate
            ))
        }

        if let mode = externalMode {
            configs.append(Profile.DisplayConfiguration(
                isBuiltIn: false,
                width: mode.width,
                height: mode.height,
                isHiDPI: mode.isHiDPI,
                refreshRate: mode.refreshRate
            ))
        }

        let profile = Profile(
            name: name.trimmingCharacters(in: .whitespaces),
            displayConfigurations: configs,
            autoApply: autoApply
        )

        profileManager.save(profile: profile)
        onDismiss()
    }
}
