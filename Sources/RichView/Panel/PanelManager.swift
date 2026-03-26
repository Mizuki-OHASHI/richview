import Cocoa
import SwiftUI

class PanelManager {
    private var panel: FloatingPanel?
    private let appState: AppState
    private let onRequestLLMCleanup: () -> Void

    init(appState: AppState, onRequestLLMCleanup: @escaping () -> Void) {
        self.appState = appState
        self.onRequestLLMCleanup = onRequestLLMCleanup
    }

    func showPanel() {
        if panel == nil {
            createPanel()
        }
        positionPanel()
        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    func hidePanel() {
        panel?.orderOut(nil)
        // Let macOS return focus to the previous app
        NSApp.hide(nil)
    }

    private func createPanel() {
        let panel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: 640, height: 440))

        let contentView = PanelContentView(
            appState: appState,
            onDismiss: { [weak self] in
                self?.hidePanel()
            },
            onRequestLLMCleanup: onRequestLLMCleanup
        )
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        // Add hosting view as subview of the visual effect view
        if let visualEffectView = panel.contentView {
            visualEffectView.addSubview(hostingView)
            NSLayoutConstraint.activate([
                hostingView.topAnchor.constraint(equalTo: visualEffectView.topAnchor),
                hostingView.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor),
                hostingView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor),
                hostingView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
            ])
        }

        self.panel = panel
    }

    private func positionPanel() {
        guard let panel = panel else { return }

        // Always center on the screen containing the mouse cursor
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) })
            ?? NSScreen.main
            ?? NSScreen.screens.first

        guard let screen = screen else { return }

        let visibleFrame = screen.visibleFrame
        let panelSize = panel.frame.size
        let origin = NSPoint(
            x: visibleFrame.midX - panelSize.width / 2,
            y: visibleFrame.midY - panelSize.height / 2
        )

        panel.setFrameOrigin(origin)
    }
}
