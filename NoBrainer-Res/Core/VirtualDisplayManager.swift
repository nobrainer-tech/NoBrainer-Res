import CoreGraphics
import Foundation
import Observation

/// Manages virtual display *configuration* only.
/// The actual CGVirtualDisplay objects are owned by VirtualDisplayKeeper (daemon).
@MainActor
@Observable
final class VirtualDisplayManager {
    private(set) var virtualDisplays: [VirtualDisplay] = []

    private let daemon = DaemonManager.shared

    init() {
        loadFromDisk()
        // Auto-start daemon if already installed but stopped
        if daemon.status == .stopped {
            daemon.installAndStart()
        }
    }

    // MARK: - Public API

    @discardableResult
    func create(config: VirtualDisplayConfig) -> Bool {
        let id = UUID()
        virtualDisplays.append(VirtualDisplay(id: id, config: config, cgDisplayID: nil))
        persist()
        daemon.signalReload()
        return true
    }

    func remove(id: UUID) {
        virtualDisplays.removeAll { $0.id == id }
        persist()
        daemon.signalReload()
    }

    func removeAll() {
        virtualDisplays.removeAll()
        persist()
        daemon.signalReload()
    }

    // MARK: - Persistence (shared JSON config used by daemon)

    func persist() {
        let configs = virtualDisplays.map(\.config)
        guard let data = try? JSONEncoder().encode(configs) else { return }
        let url = DaemonManager.configURL
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? data.write(to: url)
    }

    private func loadFromDisk() {
        guard let data    = try? Data(contentsOf: DaemonManager.configURL),
              let configs = try? JSONDecoder().decode([VirtualDisplayConfig].self, from: data)
        else { return }

        virtualDisplays = configs.map { VirtualDisplay(id: UUID(), config: $0, cgDisplayID: nil) }
    }
}
