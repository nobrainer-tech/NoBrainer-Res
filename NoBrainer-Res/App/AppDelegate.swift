import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    var shortcutManager: KeyboardShortcutManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure no Dock icon
        NSApp.setActivationPolicy(.accessory)
    }
}
