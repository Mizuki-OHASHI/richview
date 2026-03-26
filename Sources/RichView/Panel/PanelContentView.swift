import SwiftUI

struct PanelContentView: View {
    @Bindable var appState: AppState
    var onDismiss: () -> Void
    var onRequestLLMCleanup: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            contentArea
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 8) {
            // Status indicator
            statusView

            Spacer()

            // LLM toggle
            Toggle(isOn: $appState.useLLM) {
                Text("LLM")
                    .font(.system(size: 11, weight: .medium))
            }
            .toggleStyle(.switch)
            .controlSize(.mini)
            .onChange(of: appState.useLLM) { _, useLLM in
                if useLLM && appState.cleanedText.isEmpty {
                    onRequestLLMCleanup()
                }
            }

            // Copy button
            Button {
                copyToClipboard()
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 11))
            }
            .buttonStyle(.borderless)
            .help("Copy to clipboard")

            // Close button
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.borderless)
            .help("Close (Esc)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var statusView: some View {
        if appState.isStreaming {
            HStack(spacing: 4) {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.7)
                Text("Processing...")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Content

    private var contentArea: some View {
        MathRenderView(content: displayContent)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var displayContent: String {
        if appState.useLLM {
            return appState.cleanedText.isEmpty ? appState.rawText : appState.cleanedText
        } else {
            return appState.rawText
        }
    }

    // MARK: - Actions

    private func copyToClipboard() {
        let text = displayContent
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
