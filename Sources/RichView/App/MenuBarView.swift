import SwiftUI

struct MenuBarView: View {
    let appState: AppState

    var body: some View {
        Group {
            Text("Cmd+Shift+R — Render with LLM")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Cmd+Shift+D — Render directly")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            switch appState.phase {
            case .idle:
                Text("Ready")
            case .capturing:
                Text("Capturing text...")
            case .processing:
                Text("LLM processing...")
            case .rendered:
                Text("Rendered")
            case .error(let msg):
                Text("Error: \(msg)")
                    .foregroundStyle(.red)
            }

            Divider()

            Button("Quit RichView") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
