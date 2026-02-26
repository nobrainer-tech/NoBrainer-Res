import SwiftUI

struct VirtualDisplaySettingsView: View {
    @Environment(VirtualDisplayManager.self) private var virtualDisplayManager
    @State private var showAddSheet = false
    private var daemon: DaemonManager { DaemonManager.shared }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            daemonStatusBar
                .padding(.bottom, 8)

            infoBox
                .padding(.bottom, 12)

            displayList

            HStack {
                Button {
                    showAddSheet = true
                } label: {
                    Label("Add Virtual Display", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)

                Spacer()

                if !virtualDisplayManager.virtualDisplays.isEmpty {
                    Button("Remove All", role: .destructive) {
                        virtualDisplayManager.removeAll()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.top, 12)
        }
        .padding(20)
        .sheet(isPresented: $showAddSheet) {
            AddVirtualDisplaySheet(isPresented: $showAddSheet)
                .environment(virtualDisplayManager)
        }
    }

    // MARK: - Subviews

    private var daemonStatusBar: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(daemonStatusColor)
                .frame(width: 8, height: 8)

            Text(daemonStatusText)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            switch daemon.status {
            case .notInstalled:
                Button("Install Background Service") {
                    daemon.installAndStart()
                }
                .buttonStyle(.bordered)
                .font(.caption)

            case .installing:
                ProgressView()
                    .scaleEffect(0.6)

            case .stopped:
                Button("Start") {
                    daemon.installAndStart()
                }
                .buttonStyle(.bordered)
                .font(.caption)

            case .running:
                Button("Refresh") {
                    daemon.refreshStatus()
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)

            case .error:
                Button("Retry") {
                    daemon.installAndStart()
                }
                .buttonStyle(.bordered)
                .font(.caption)
            }
        }
        .padding(8)
        .background(.quinary, in: RoundedRectangle(cornerRadius: 6))
    }

    private var daemonStatusColor: Color {
        switch daemon.status {
        case .running:       return .green
        case .installing:    return .yellow
        case .stopped:       return .orange
        case .notInstalled:  return .gray
        case .error:         return .red
        }
    }

    private var daemonStatusText: String {
        switch daemon.status {
        case .running:          return "Background service running — displays survive app restart"
        case .installing:       return "Installing background service…"
        case .stopped:          return "Background service stopped"
        case .notInstalled:     return "Background service not installed"
        case .error(let msg):   return "Error: \(msg)"
        }
    }

    private var infoBox: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
                .padding(.top, 1)

            Text("Virtual displays work without physical hardware. Useful for headless Mac Mini — connect via Screen Sharing and use the virtual display as your primary screen.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(.quinary, in: RoundedRectangle(cornerRadius: 8))
    }

    private var displayList: some View {
        Group {
            if virtualDisplayManager.virtualDisplays.isEmpty {
                emptyState
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
            } else {
                List {
                    ForEach(virtualDisplayManager.virtualDisplays) { display in
                        displayRow(display)
                    }
                }
                .listStyle(.inset)
                .frame(height: 140)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "square.dashed")
                .font(.system(size: 28))
                .foregroundStyle(.tertiary)
            Text("No virtual displays")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private func displayRow(_ display: VirtualDisplay) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(display.config.name)
                    .font(.body)

                HStack(spacing: 6) {
                    Text("\(display.config.width)×\(display.config.height) @ \(Int(display.config.refreshRate))Hz")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if display.config.hiDPI {
                        Text("HiDPI")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.blue.opacity(0.15), in: RoundedRectangle(cornerRadius: 3))
                            .foregroundStyle(.blue)
                    }
                }
            }

            Spacer()

            if let cgID = display.cgDisplayID {
                VStack(alignment: .trailing, spacing: 2) {
                    Label("Active", systemImage: "circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .labelStyle(.titleAndIcon)

                    Text("ID: \(cgID)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            } else {
                Label("Inactive", systemImage: "circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .labelStyle(.titleAndIcon)
            }

            Button {
                virtualDisplayManager.remove(id: display.id)
            } label: {
                Image(systemName: "minus.circle")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
            .help("Remove")
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Sheet

private struct AddVirtualDisplaySheet: View {
    @Environment(VirtualDisplayManager.self) private var virtualDisplayManager
    @Binding var isPresented: Bool

    @State private var name = "Virtual 3024×1900"
    @State private var width = 3024
    @State private var height = 1900
    @State private var refreshRate = 60.0
    @State private var hiDPI = false
    @State private var connectOnStartup = true

    @State private var widthText = "3024"
    @State private var heightText = "1900"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Virtual Display")
                .font(.headline)

            // Presets
            VStack(alignment: .leading, spacing: 6) {
                Text("Presets")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    ForEach(VirtualDisplayConfig.presets, id: \.self) { preset in
                        Button("\(preset.width)×\(preset.height)") {
                            applyPreset(preset)
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }
                }
            }

            Divider()

            // Custom fields
            Form {
                TextField("Name", text: $name)

                HStack(spacing: 4) {
                    TextField("Width", text: $widthText)
                        .frame(width: 70)
                        .onChange(of: widthText) { _, v in width = Int(v) ?? width }

                    Text("×")

                    TextField("Height", text: $heightText)
                        .frame(width: 70)
                        .onChange(of: heightText) { _, v in height = Int(v) ?? height }

                    Text("px")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Slider(value: $refreshRate, in: 30...120, step: 30)
                    Text("\(Int(refreshRate)) Hz")
                        .frame(width: 45, alignment: .trailing)
                        .foregroundStyle(.secondary)
                }

                Toggle("HiDPI (2× framebuffer)", isOn: $hiDPI)
                Toggle("Connect on startup", isOn: $connectOnStartup)
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Create") {
                    let config = VirtualDisplayConfig(
                        name: name,
                        width: width,
                        height: height,
                        refreshRate: refreshRate,
                        hiDPI: hiDPI,
                        connectOnStartup: connectOnStartup
                    )
                    virtualDisplayManager.create(config: config)
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || width < 640 || height < 480)
            }
        }
        .padding(20)
        .frame(width: 420)
    }

    private func applyPreset(_ preset: VirtualDisplayConfig) {
        name = preset.name
        width = preset.width
        height = preset.height
        widthText = "\(preset.width)"
        heightText = "\(preset.height)"
        refreshRate = preset.refreshRate
    }
}
