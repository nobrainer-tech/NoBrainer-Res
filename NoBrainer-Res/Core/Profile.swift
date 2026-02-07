import Foundation

struct Profile: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var displayConfigurations: [DisplayConfiguration]
    let createdAt: Date

    struct DisplayConfiguration: Codable, Hashable {
        let displayID: UInt32
        let modeID: Int32
        let width: Int
        let height: Int
        let isHiDPI: Bool
        let refreshRate: Double

        var resolution: String {
            "\(width) x \(height)"
        }
    }

    init(id: UUID = UUID(), name: String, displayConfigurations: [DisplayConfiguration] = [], createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.displayConfigurations = displayConfigurations
        self.createdAt = createdAt
    }
}
