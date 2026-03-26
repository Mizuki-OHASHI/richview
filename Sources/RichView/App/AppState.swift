import Foundation

@Observable
class AppState {
    enum Phase {
        case idle
        case capturing
        case processing
        case rendered
        case error(String)
    }

    var phase: Phase = .idle
    var rawText: String = ""
    var cleanedText: String = ""
    var isStreaming: Bool = false
    var useLLM: Bool = true
}
