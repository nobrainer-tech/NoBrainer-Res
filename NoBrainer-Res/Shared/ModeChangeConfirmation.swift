import AppKit

/// Asks whether to keep a new display mode and answers "no" when the user does not respond,
/// the same safety net System Settings uses for resolution changes.
@MainActor
final class ModeChangeConfirmation: NSObject {
    private static let timeoutSeconds = 15

    private let alert = NSAlert()
    private var remainingSeconds = ModeChangeConfirmation.timeoutSeconds

    static func ask() -> Bool {
        ModeChangeConfirmation().run()
    }

    private func run() -> Bool {
        alert.messageText = "Keep this display mode?"
        alert.addButton(withTitle: "Keep")
        alert.addButton(withTitle: "Revert")
        updateCountdown()

        let timer = Timer(timeInterval: 1, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .modalPanel)
        NSApp.activate()
        let response = alert.runModal()
        timer.invalidate()
        return response == .alertFirstButtonReturn
    }

    @objc private func tick() {
        remainingSeconds -= 1
        if remainingSeconds <= 0 {
            NSApp.abortModal()
        } else {
            updateCountdown()
        }
    }

    private func updateCountdown() {
        alert.informativeText = "The previous mode will be restored in \(remainingSeconds) seconds."
    }
}
