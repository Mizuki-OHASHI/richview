import FoundationModels

class LaTeXCleanupService {
    func cleanup(text: String) -> AsyncStream<String> {
        AsyncStream { continuation in
            Task {
                do {
                    let session = LanguageModelSession(
                        instructions: LaTeXPrompts.systemInstruction
                    )
                    let stream = session.streamResponse(to: text)
                    for try await snapshot in stream {
                        continuation.yield(snapshot.content)
                    }
                } catch {
                    print("[RichView] LLM cleanup error: \(error)")
                }
                continuation.finish()
            }
        }
    }
}
