import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    private var hotkeyManager: HotkeyManager?
    private var panelManager: PanelManager?
    private let textCapture = AccessibilityCapture()
    private let clipboardCapture = ClipboardCapture()
    private let llmService = LaTeXCleanupService()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock
        NSApp.setActivationPolicy(.accessory)

        // Prompt for Accessibility permission if needed
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)

        // Setup panel manager
        panelManager = PanelManager(appState: appState) { [weak self] in
            self?.requestLLMCleanup()
        }

        // Setup hotkeys
        hotkeyManager = HotkeyManager()
        hotkeyManager?.onHotkeyWithLLM = { [weak self] in
            self?.handleHotkey(useLLM: true)
        }
        hotkeyManager?.onHotkeyWithoutLLM = { [weak self] in
            self?.handleHotkey(useLLM: false)
        }
        hotkeyManager?.register()

        // Re-register event tap on wake from sleep
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    @objc private func handleWake() {
        hotkeyManager?.unregister()
        hotkeyManager?.register()
    }

    private func handleHotkey(useLLM: Bool) {
        Task { @MainActor in
            appState.phase = .capturing
            appState.useLLM = useLLM

            // Try Accessibility API first, then clipboard fallback
            var text = textCapture.captureSelectedText()
            if text == nil || text!.isEmpty {
                text = clipboardCapture.captureSelectedText()
            }

            guard let selectedText = text, !selectedText.isEmpty else {
                appState.phase = .error("No text selected")
                // Reset to idle after a brief delay
                try? await Task.sleep(for: .seconds(2))
                appState.phase = .idle
                return
            }

            appState.rawText = AppDelegate.dedent(selectedText)
            appState.cleanedText = ""
            appState.phase = useLLM ? .processing : .rendered

            // Show panel immediately
            panelManager?.showPanel()

            if useLLM {
                await runLLMCleanup()
            } else {
                // Direct render: use raw text as-is
                appState.cleanedText = selectedText
            }
        }
    }

    /// Remove common leading whitespace from all lines (like Python's textwrap.dedent).
    private static func dedent(_ text: String) -> String {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let minIndent = lines
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { $0.prefix(while: { $0 == " " || $0 == "\t" }).count }
            .min() ?? 0
        guard minIndent > 0 else { return text }
        return lines.map { line in
            line.count >= minIndent ? String(line.dropFirst(minIndent)) : line
        }.joined(separator: "\n")
    }

    private func requestLLMCleanup() {
        Task { @MainActor in
            guard !appState.rawText.isEmpty, appState.cleanedText.isEmpty else { return }
            appState.phase = .processing
            await runLLMCleanup()
        }
    }

    private func runLLMCleanup() async {
        appState.isStreaming = true
        for await cleaned in llmService.cleanup(text: appState.rawText) {
            appState.cleanedText = cleaned
        }
        appState.isStreaming = false
        appState.phase = .rendered
    }
}
