import CoreGraphics

struct DisplayMode: Identifiable, Hashable {
    let id: Int32
    let width: Int
    let height: Int
    let refreshRate: Double
    let isHiDPI: Bool
    let bitDepth: Int
    let isNative: Bool
    let isCurrent: Bool

    var resolution: String {
        "\(width) x \(height)"
    }

    var refreshRateLabel: String {
        refreshRate.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(refreshRate)) Hz"
            : String(format: "%.1f Hz", refreshRate)
    }

    var scaleLabel: String {
        isHiDPI ? "HiDPI" : "Low Res"
    }

    var summary: String {
        var parts = [resolution]
        if refreshRate > 0 {
            parts.append(refreshRateLabel)
        }
        if isHiDPI {
            parts.append("HiDPI")
        }
        return parts.joined(separator: " - ")
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: DisplayMode, rhs: DisplayMode) -> Bool {
        lhs.id == rhs.id
    }
}

extension DisplayMode {
    init(cgMode: CGDisplayMode, isCurrent: Bool = false, isNative: Bool = false) {
        self.id = cgMode.ioDisplayModeID
        self.width = cgMode.width
        self.height = cgMode.height
        self.refreshRate = cgMode.refreshRate
        self.isHiDPI = cgMode.pixelWidth > cgMode.width
        self.bitDepth = cgMode.pixelWidth > 0 ? 32 : 0
        self.isCurrent = isCurrent
        self.isNative = isNative
    }

    /// Groups modes by (width, height, isHiDPI, refreshRate) to remove true duplicates
    /// while preserving different refresh rate options.
    static func deduplicate(_ modes: [DisplayMode]) -> [DisplayMode] {
        var grouped: [String: DisplayMode] = [:]

        for mode in modes {
            let roundedRate = Int(mode.refreshRate)
            let key = "\(mode.width)x\(mode.height)_\(mode.isHiDPI)_\(roundedRate)"
            if let existing = grouped[key] {
                if mode.isCurrent {
                    grouped[key] = mode
                } else if !existing.isCurrent && mode.refreshRate > existing.refreshRate {
                    grouped[key] = mode
                }
            } else {
                grouped[key] = mode
            }
        }

        return grouped.values
            .sorted { lhs, rhs in
                if lhs.width != rhs.width { return lhs.width > rhs.width }
                if lhs.height != rhs.height { return lhs.height > rhs.height }
                if lhs.isHiDPI != rhs.isHiDPI { return lhs.isHiDPI }
                return lhs.refreshRate > rhs.refreshRate
            }
    }
}
