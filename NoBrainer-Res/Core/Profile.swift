import Foundation

struct Profile: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var displayConfigurations: [DisplayConfiguration]
    var autoApply: Bool
    let createdAt: Date

    struct DisplayConfiguration: Codable, Hashable {
        var isBuiltIn: Bool
        let width: Int
        let height: Int
        let isHiDPI: Bool
        let refreshRate: Double

        var resolution: String {
            "\(width) x \(height)"
        }
    }

    init(id: UUID = UUID(), name: String, displayConfigurations: [DisplayConfiguration] = [], autoApply: Bool = false, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.displayConfigurations = displayConfigurations
        self.autoApply = autoApply
        self.createdAt = createdAt
    }
}
