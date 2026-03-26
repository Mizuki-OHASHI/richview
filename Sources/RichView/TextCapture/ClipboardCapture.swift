import Cocoa

/// Fallback text capture via simulated Cmd+C.
/// Used when Accessibility API fails (e.g., Electron apps).
class ClipboardCapture {
    func captureSelectedText() -> String? {
        // Save current clipboard content
        let pasteboard = NSPasteboard.general
        let savedContents = pasteboard.string(forType: .string)
        let savedChangeCount = pasteboard.changeCount

        // Simulate Cmd+C
        let source = CGEventSource(stateID: .hidSystemState)
        let cKeyCode: CGKeyCode = 0x08

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: cKeyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: cKeyCode, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)

        // Brief wait for the copy to propagate
        usleep(150_000) // 150ms

        // Read new clipboard content
        let copiedText = pasteboard.string(forType: .string)

        // Restore previous clipboard if it changed
        if pasteboard.changeCount != savedChangeCount {
            pasteboard.clearContents()
            if let saved = savedContents {
                pasteboard.setString(saved, forType: .string)
            }
        }

        // Only return if clipboard actually changed
        if pasteboard.changeCount != savedChangeCount || copiedText != savedContents {
            return copiedText
        }

        return copiedText
    }
}
