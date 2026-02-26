import Foundation
import Observation

@MainActor
@Observable
final class DaemonManager {

    enum Status: Equatable {
        case notInstalled
        case installing
        case running
        case stopped
        case error(String)
    }

    private(set) var status: Status = .notInstalled

    static let label  = "tech.nobrainer.vdkeeper"
    static let shared = DaemonManager()

    // MARK: - Paths

    static var appSupportDir: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("NoBrainer Res")
    }

    static var configURL: URL {
        appSupportDir.appendingPathComponent("virtual-displays.json")
    }

    private var daemonBinaryURL: URL {
        Self.appSupportDir.appendingPathComponent("VirtualDisplayKeeper")
    }

    private var launchAgentURL: URL {
        FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
            .appendingPathComponent("LaunchAgents/\(Self.label).plist")
    }

    private var pidURL: URL {
        Self.appSupportDir.appendingPathComponent("daemon.pid")
    }

    // MARK: - Init

    private init() {
        refreshStatus()
    }

    // MARK: - Public API

    func installAndStart() {
        status = .installing
        Task.detached(priority: .userInitiated) {
            do {
                try await self.doInstall()
                await MainActor.run { self.status = .running }
            } catch {
                await MainActor.run { self.status = .error(error.localizedDescription) }
            }
        }
    }

    func stop() {
        run("/bin/launchctl", "unload", launchAgentURL.path)
        refreshStatus()
    }

    func uninstall() {
        run("/bin/launchctl", "unload", launchAgentURL.path)
        try? FileManager.default.removeItem(at: launchAgentURL)
        try? FileManager.default.removeItem(at: daemonBinaryURL)
        refreshStatus()
    }

    func signalReload() {
        guard let pid = daemonPID() else { return }
        kill(pid, SIGUSR1)
    }

    func refreshStatus() {
        let out = run("/bin/launchctl", "list", Self.label)
        if out.contains("\"PID\"") {
            status = .running
        } else if FileManager.default.fileExists(atPath: launchAgentURL.path) {
            status = .stopped
        } else {
            status = .notInstalled
        }
    }

    // MARK: - Private

    private func doInstall() async throws {
        guard let bundleBinary = Bundle.main.url(forAuxiliaryExecutable: "VirtualDisplayKeeper") else {
            throw DaemonError.binaryNotFound
        }

        try FileManager.default.createDirectory(at: Self.appSupportDir, withIntermediateDirectories: true)

        if FileManager.default.fileExists(atPath: daemonBinaryURL.path) {
            try FileManager.default.removeItem(at: daemonBinaryURL)
        }
        try FileManager.default.copyItem(at: bundleBinary, to: daemonBinaryURL)
        try FileManager.default.setAttributes([.posixPermissions: 0o755],
                                               ofItemAtPath: daemonBinaryURL.path)
        try writeLaunchAgentPlist()

        let loadDir = launchAgentURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: loadDir, withIntermediateDirectories: true)

        run("/bin/launchctl", "unload", launchAgentURL.path) // ignore error if not loaded
        run("/bin/launchctl", "load", "-w", launchAgentURL.path)
    }

    private func writeLaunchAgentPlist() throws {
        let logsDir = NSHomeDirectory() + "/Library/Logs"
        let plist: [String: Any] = [
            "Label":              Self.label,
            "ProgramArguments":  [daemonBinaryURL.path],
            "RunAtLoad":         true,
            "KeepAlive":         true,
            "StandardOutPath":   logsDir + "/VirtualDisplayKeeper.log",
            "StandardErrorPath": logsDir + "/VirtualDisplayKeeper.log",
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try data.write(to: launchAgentURL)
    }

    private func daemonPID() -> Int32? {
        guard let s = try? String(contentsOf: pidURL, encoding: .utf8)
                        .trimmingCharacters(in: .whitespacesAndNewlines),
              let pid = Int32(s)
        else { return nil }
        return pid
    }

    @discardableResult
    private func run(_ path: String, _ args: String...) -> String {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: path)
        proc.arguments = args
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError  = pipe
        try? proc.run()
        proc.waitUntilExit()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }

    // MARK: - Errors

    enum DaemonError: LocalizedError {
        case binaryNotFound
        var errorDescription: String? {
            switch self {
            case .binaryNotFound:
                return "VirtualDisplayKeeper not found in app bundle. Rebuild the app."
            }
        }
    }
}
