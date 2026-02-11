import Foundation
import Observation

@MainActor
@Observable
final class DisplayPlacerManager {
    private(set) var isInstalled: Bool = false
    private(set) var displays: [DisplayPlacerDisplay] = []
    private(set) var lastError: String?
    
    init() {
        checkInstallation()
        if isInstalled {
            refreshDisplays()
        }
    }
    
    func checkInstallation() {
        let task = Process()
        task.launchPath = "/usr/bin/which"
        task.arguments = ["displayplacer"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            isInstalled = task.terminationStatus == 0
        } catch {
            isInstalled = false
        }
    }
    
    func refreshDisplays() {
        guard isInstalled else { return }
        
        let task = Process()
        task.launchPath = "/opt/homebrew/bin/displayplacer"
        task.arguments = ["list"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                displays = parseDisplayPlacerOutput(output)
                lastError = nil
            } else {
                lastError = "Failed to get display list"
            }
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    func setResolution(displayId: String, width: Int, height: Int, hiDPI: Bool = false) -> Bool {
        guard isInstalled else {
            lastError = "displayplacer not installed"
            return false
        }
        
        // Find the best matching mode
        guard let display = displays.first(where: { $0.persistentId == displayId }),
              let mode = findBestMode(for: display, width: width, height: height, hiDPI: hiDPI) else {
            lastError = "No matching resolution found"
            return false
        }
        
        let task = Process()
        task.launchPath = "/opt/homebrew/bin/displayplacer"
        task.arguments = [
            "id:\(displayId)",
            "res:\(mode.width)x\(mode.height)",
            "color_depth:\(mode.colorDepth)",
            "scaling:\(hiDPI ? "on" : "off")",
            "hz:\(mode.hertz)"
        ]
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                refreshDisplays()
                return true
            } else {
                lastError = "Failed to set resolution"
                return false
            }
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }
    
    func forceResolution(displayId: String, width: Int, height: Int) -> Bool {
        // This attempts to use displayplacer with the exact resolution
        // Works best with headless adapters or when system allows custom modes
        return setResolution(displayId: displayId, width: width, height: height, hiDPI: false)
    }
    
    private func parseDisplayPlacerOutput(_ output: String) -> [DisplayPlacerDisplay] {
        var displays: [DisplayPlacerDisplay] = []
        var currentDisplay: DisplayPlacerDisplay?
        var currentModes: [DisplayPlacerMode] = []
        
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            if line.starts(with: "Persistent screen id:") {
                if var display = currentDisplay {
                    display.modes = currentModes
                    displays.append(display)
                }
                let id = line.replacingOccurrences(of: "Persistent screen id: ", with: "").trimmingCharacters(in: .whitespaces)
                currentDisplay = DisplayPlacerDisplay(persistentId: id)
                currentModes = []
            } else if line.starts(with: "Type:") {
                currentDisplay?.type = line.replacingOccurrences(of: "Type: ", with: "").trimmingCharacters(in: .whitespaces)
            } else if line.starts(with: "Resolution:") {
                let resStr = line.replacingOccurrences(of: "Resolution: ", with: "").trimmingCharacters(in: .whitespaces)
                currentDisplay?.currentResolution = resStr
            } else if line.starts(with: "mode ") {
                // Parse mode line: "mode 0: res:800x600 hz:60 color_depth:8 scaling:on"
                if let mode = parseModeLine(line) {
                    currentModes.append(mode)
                }
            }
        }
        
        if var display = currentDisplay {
            display.modes = currentModes
            displays.append(display)
        }
        
        return displays
    }
    
    private func parseModeLine(_ line: String) -> DisplayPlacerMode? {
        // mode 0: res:800x600 hz:60 color_depth:8 scaling:on
        let pattern = "res:(\\d+)x(\\d+) hz:(\\d+) color_depth:(\\d+) scaling:(\\w+)"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(line.startIndex..., in: line)
            
            if let match = regex.firstMatch(in: line, options: [], range: range) {
                let width = Int((line as NSString).substring(with: match.range(at: 1))) ?? 0
                let height = Int((line as NSString).substring(with: match.range(at: 2))) ?? 0
                let hertz = Int((line as NSString).substring(with: match.range(at: 3))) ?? 60
                let colorDepth = Int((line as NSString).substring(with: match.range(at: 4))) ?? 8
                let scaling = (line as NSString).substring(with: match.range(at: 5)) == "on"
                
                return DisplayPlacerMode(
                    width: width,
                    height: height,
                    hertz: hertz,
                    colorDepth: colorDepth,
                    scaling: scaling
                )
            }
        } catch {
            print("Failed to parse mode: \(error)")
        }
        
        return nil
    }
    
    private func findBestMode(for display: DisplayPlacerDisplay, width: Int, height: Int, hiDPI: Bool) -> DisplayPlacerMode? {
        // First try exact match
        if let exact = display.modes.first(where: { $0.width == width && $0.height == height && $0.scaling == hiDPI }) {
            return exact
        }
        
        // Then try without scaling preference
        if let withoutScaling = display.modes.first(where: { $0.width == width && $0.height == height }) {
            return withoutScaling
        }
        
        // Finally try closest resolution
        return display.modes.min(by: {
            let diff1 = abs($0.width - width) + abs($0.height - height)
            let diff2 = abs($1.width - width) + abs($1.height - height)
            return diff1 < diff2
        })
    }
}

struct DisplayPlacerDisplay: Identifiable {
    let persistentId: String
    var type: String = ""
    var currentResolution: String = ""
    var modes: [DisplayPlacerMode] = []
    
    var id: String { persistentId }
}

struct DisplayPlacerMode: Identifiable {
    let width: Int
    let height: Int
    let hertz: Int
    let colorDepth: Int
    let scaling: Bool
    
    var id: String { "\(width)x\(height)@\(hertz)-\(scaling)" }
    
    var description: String {
        "\(width)x\(height) @ \(hertz)Hz \(scaling ? "HiDPI" : "")"
    }
}
