import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure no Dock icon
        NSApp.setActivationPolicy(.accessory)
    }
}
