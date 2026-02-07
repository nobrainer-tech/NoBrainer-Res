import SwiftUI

struct DisplaySectionView: View {
    let display: Display
    let onModeSelect: (DisplayMode) -> Void
    @AppStorage(Constants.UserDefaultsKeys.showHiDPIOnly) private var showHiDPIOnly = false

    private var filteredModes: [DisplayMode] {
        if showHiDPIOnly {
            return display.sortedModes.filter(\.isHiDPI)
        }
        return display.sortedModes
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: display.isBuiltIn ? "laptopcomputer" : "display")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                Text(display.name)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                if let current = display.currentMode {
                    Text(current.resolution)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)

            Divider()
                .padding(.horizontal, 8)

            ForEach(filteredModes) { mode in
                DisplayModeRowView(
                    mode: mode,
                    isCurrent: mode.id == display.currentMode?.id
                ) {
                    onModeSelect(mode)
                }
            }
        }
    }
}
