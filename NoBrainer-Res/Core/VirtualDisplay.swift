import CoreGraphics
import Foundation

struct VirtualDisplay: Identifiable {
    let id: UUID
    var config: VirtualDisplayConfig
    var cgDisplayID: CGDirectDisplayID?
}

struct VirtualDisplayConfig: Codable, Hashable {
    var name: String
    var width: Int
    var height: Int
    var refreshRate: Double
    var hiDPI: Bool
    var connectOnStartup: Bool

    static let presets: [VirtualDisplayConfig] = [
        VirtualDisplayConfig(name: "Virtual 3024×1900", width: 3024, height: 1900, refreshRate: 60.0, hiDPI: false, connectOnStartup: true),
        VirtualDisplayConfig(name: "Virtual 2560×1600", width: 2560, height: 1600, refreshRate: 60.0, hiDPI: false, connectOnStartup: true),
        VirtualDisplayConfig(name: "Virtual 1920×1200", width: 1920, height: 1200, refreshRate: 60.0, hiDPI: false, connectOnStartup: true),
        VirtualDisplayConfig(name: "Virtual 3840×2160", width: 3840, height: 2160, refreshRate: 60.0, hiDPI: false, connectOnStartup: true),
    ]
}
