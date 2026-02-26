import SwiftUI

struct VirtualDisplaySectionView: View {
    @Environment(VirtualDisplayManager.self) private var virtualDisplayManager
    @State private var hoveredID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader

            Divider()
                .padding(.horizontal, 8)

            ForEach(virtualDisplayManager.virtualDisplays) { display in
                displayRow(display)
            }
        }
    }

    // MARK: - Subviews

    private var sectionHeader: some View {
        HStack {
            Image(systemName: "square.dashed")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Text("Virtual Displays")
                .font(.headline)

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private func displayRow(_ display: VirtualDisplay) -> some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 1) {
                Text(display.config.name)
                    .font(.subheadline)
                    .lineLimit(1)

                Text("\(display.config.width)×\(display.config.height) @ \(Int(display.config.refreshRate))Hz")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if display.cgDisplayID != nil {
                Label("Active", systemImage: "circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
                    .labelStyle(.titleAndIcon)
            } else {
                Label("Inactive", systemImage: "circle")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .labelStyle(.titleAndIcon)
            }

            if hoveredID == display.id {
                Button {
                    virtualDisplayManager.remove(id: display.id)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Remove virtual display")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .onHover { hoveredID = $0 ? display.id : nil }
    }
}
