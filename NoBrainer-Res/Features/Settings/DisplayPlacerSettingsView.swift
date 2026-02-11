import SwiftUI

struct DisplayPlacerSettingsView: View {
    @State private var placerManager = DisplayPlacerManager()
    @State private var customWidth: String = ""
    @State private var customHeight: String = ""
    @State private var useHiDPI: Bool = false
    @State private var showSuccess: Bool = false
    @State private var showError: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "rectangle.badge.plus")
                    .font(.title2)
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading) {
                    Text("Advanced Resolution Control")
                        .font(.headline)
                    Text("Force custom resolutions via displayplacer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Installation status
            if !placerManager.isInstalled {
                InstallationRequiredView()
            } else {
                DisplaysListView(
                    placerManager: placerManager,
                    customWidth: $customWidth,
                    customHeight: $customHeight,
                    useHiDPI: $useHiDPI,
                    showSuccess: $showSuccess,
                    showError: $showError
                )
            }
            
            // Info box
            InfoBox()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct InstallationRequiredView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            
            Text("displayplacer Required")
                .font(.headline)
            
            Text("To force custom resolutions, you need to install displayplacer via Homebrew.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Installation command:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Text("brew install displayplacer")
                        .font(.system(.body, design: .monospaced))
                        .padding(8)
                        .background(Color(.textBackgroundColor))
                        .cornerRadius(6)
                    
                    Button {
                        copyToClipboard("brew install displayplacer")
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding()
            .background(Color(.windowBackgroundColor).opacity(0.5))
            .cornerRadius(8)
            
            Button("Open Terminal") {
                NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"))
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
    }
}

struct DisplaysListView: View {
    @State var placerManager: DisplayPlacerManager
    @Binding var customWidth: String
    @Binding var customHeight: String
    @Binding var useHiDPI: Bool
    @Binding var showSuccess: Bool
    @Binding var showError: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Detected Displays (\(placerManager.displays.count))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    placerManager.refreshDisplays()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
            }
            
            if placerManager.displays.isEmpty {
                Text("No displays detected")
                    .foregroundStyle(.secondary)
                    .italic()
            } else {
                ForEach(placerManager.displays) { display in
                    DisplayCard(
                        display: display,
                        customWidth: $customWidth,
                        customHeight: $customHeight,
                        useHiDPI: $useHiDPI,
                        placerManager: placerManager,
                        showSuccess: $showSuccess,
                        showError: $showError
                    )
                }
            }
            
            if let error = placerManager.lastError {
                HStack {
                    Image(systemName: "exclamationmark.circle")
                    Text(error)
                }
                .foregroundStyle(.red)
                .font(.caption)
            }
        }
    }
}

struct DisplayCard: View {
    let display: DisplayPlacerDisplay
    @Binding var customWidth: String
    @Binding var customHeight: String
    @Binding var useHiDPI: Bool
    @State var placerManager: DisplayPlacerManager
    @Binding var showSuccess: Bool
    @Binding var showError: Bool
    @State private var isApplying: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Display info header
            HStack {
                Image(systemName: "display")
                VStack(alignment: .leading) {
                    Text(display.type)
                        .fontWeight(.medium)
                    Text("Current: \(display.currentResolution)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("ID: \(display.persistentId.prefix(8))...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            // Custom resolution input
            VStack(alignment: .leading, spacing: 8) {
                Text("Force Custom Resolution")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    HStack {
                        TextField("Width", text: $customWidth)
                            .frame(width: 60)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.center)
                        Text("×")
                            .foregroundStyle(.secondary)
                        TextField("Height", text: $customHeight)
                            .frame(width: 60)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.center)
                    }
                    
                    Toggle("HiDPI", isOn: $useHiDPI)
                        .toggleStyle(.checkbox)
                    
                    Spacer()
                    
                    Button {
                        applyCustomResolution()
                    } label: {
                        if isApplying {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("Apply")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(customWidth.isEmpty || customHeight.isEmpty || isApplying)
                }
                
                // Quick presets for common resolutions
                HStack(spacing: 4) {
                    ForEach(["1920x1080", "2560x1440", "3840x2160", "5120x2880"], id: \.self) { preset in
                        Button {
                            let parts = preset.components(separatedBy: "x")
                            if parts.count == 2 {
                                customWidth = parts[0]
                                customHeight = parts[1]
                            }
                        } label: {
                            Text(preset)
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
            
            // Available modes disclosure
            if !display.modes.isEmpty {
                DisclosureGroup("Available Modes (\(display.modes.count))") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(display.modes.prefix(10)) { mode in
                                ModeBadge(mode: mode)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(8)
    }
    
    private func applyCustomResolution() {
        guard let width = Int(customWidth),
              let height = Int(customHeight) else {
            return
        }
        
        isApplying = true
        
        Task {
            let success = placerManager.forceResolution(
                displayId: display.persistentId,
                width: width,
                height: height
            )
            
            await MainActor.run {
                isApplying = false
                if success {
                    showSuccess = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showSuccess = false
                    }
                } else {
                    showError = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showError = false
                    }
                }
            }
        }
    }
}

struct ModeBadge: View {
    let mode: DisplayPlacerMode
    
    var body: some View {
        Text(mode.description)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(mode.scaling ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
            .foregroundStyle(mode.scaling ? .blue : .primary)
            .cornerRadius(4)
    }
}

struct InfoBox: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle")
                Text("About Forced Resolutions")
                    .fontWeight(.medium)
            }
            
            Text("This feature uses displayplacer to set resolutions that may not appear in standard system preferences. Works best with headless HDMI adapters (dummy plugs) for remote Mac access.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 4) {
                Image(systemName: "link")
                Link("Learn more about headless adapters", destination: URL(string: "https://nobrainertech.gumroad.com/l/nobrainer-res")!)
                    .font(.caption)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

private func copyToClipboard(_ text: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
}

#Preview {
    DisplayPlacerSettingsView()
}
