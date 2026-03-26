import FoundationModels
import Foundation

class LaTeXCleanupService {
    /// A chunk is either a line that needs LLM processing or one that doesn't.
    private enum Chunk {
        case passthrough(String)   // Japanese-only line — skip LLM
        case needsLLM(String)      // math or mixed content — send to LLM
    }

    /// Japanese-only line: contains Japanese chars and/or spaces/punctuation, but no math indicators.
    private static let japaneseOnly: NSRegularExpression = {
        // Line consists entirely of: Japanese chars, whitespace, ASCII/JP punctuation, basic Latin words
        // If it contains math-like tokens (backslash, braces, ^, _, $, [, ]), it's NOT Japanese-only
        let pattern = "^[\\u3040-\\u309F\\u30A0-\\u30FF\\u4E00-\\u9FFF\\uFF00-\\uFFEF\\u3000-\\u303F\\s\\p{P}a-zA-Z0-9 ]*$"
        return try! NSRegularExpression(pattern: pattern)
    }()

    /// Check if a line looks like it's only natural language (no math).
    private func isJapaneseOrPlainText(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return true }
        // If line contains math indicators, it needs LLM
        let mathIndicators: [String] = ["\\", "{", "}", "^", "_", "$", "frac", "sqrt", "sum", "int",
                                         "alpha", "beta", "gamma", "theta", "sigma", "delta", "lambda",
                                         "mu", "pi", "phi", "psi", "omega", "epsilon", "nabla",
                                         "partial", "infty", "cdot", "times", "equiv", "approx",
                                         "leq", "geq", "neq", "mid", "lim", "log", "exp", "max", "min"]
        for indicator in mathIndicators {
            if trimmed.contains(indicator) { return false }
        }
        return true
    }

    /// Split text into chunks, grouping math block lines (between standalone [ and ]).
    private func splitIntoChunks(_ text: String) -> [Chunk] {
        let lines = text.components(separatedBy: "\n")
        var chunks: [Chunk] = []
        var mathBlock: [String] = []
        var inMathBlock = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if inMathBlock {
                mathBlock.append(line)
                // End of math block: standalone ] or \]
                if trimmed == "]" || trimmed == "\\]" {
                    chunks.append(.needsLLM(mathBlock.joined(separator: "\n")))
                    mathBlock = []
                    inMathBlock = false
                }
            } else if trimmed == "[" || trimmed == "\\[" {
                // Start of math block
                inMathBlock = true
                mathBlock = [line]
            } else if isJapaneseOrPlainText(line) {
                chunks.append(.passthrough(line))
            } else {
                chunks.append(.needsLLM(line))
            }
        }

        // If we ended while still in a math block, flush it
        if !mathBlock.isEmpty {
            chunks.append(.needsLLM(mathBlock.joined(separator: "\n")))
        }

        return chunks
    }

    /// Strip code fences that the LLM wraps around output.
    private static func stripCodeFences(_ text: String) -> String {
        var s = text
        // Full wrap: ```lang\n...\n```
        if let range = s.range(of: #"^```\w*\s*\n?([\s\S]*?)\n?\s*```\s*$"#, options: .regularExpression) {
            let inner = s[range]
                .drop(while: { $0 != "\n" }).dropFirst() // drop ```lang\n
            if let end = inner.range(of: #"\n?\s*```\s*$"#, options: .regularExpression) {
                s = String(inner[inner.startIndex..<end.lowerBound])
            }
        }
        return s
    }

    func cleanup(text: String) -> AsyncStream<String> {
        let chunks = splitIntoChunks(text)

        return AsyncStream { continuation in
            Task {
                var results: [String] = Array(repeating: "", count: chunks.count)

                // Fill in passthrough chunks immediately
                for (i, chunk) in chunks.enumerated() {
                    if case .passthrough(let line) = chunk {
                        results[i] = line
                    }
                }

                // Process LLM chunks sequentially
                for (i, chunk) in chunks.enumerated() {
                    guard case .needsLLM(let content) = chunk else { continue }

                    do {
                        let session = LanguageModelSession(
                            instructions: LaTeXPrompts.systemInstruction
                        )
                        let stream = session.streamResponse(to: content)
                        for try await snapshot in stream {
                            results[i] = Self.stripCodeFences(snapshot.content)
                            continuation.yield(results.joined(separator: "\n"))
                        }
                    } catch {
                        print("[RichView] LLM chunk error: \(error)")
                        // Fallback: keep original content
                        results[i] = content
                        continuation.yield(results.joined(separator: "\n"))
                    }
                }

                continuation.yield(results.joined(separator: "\n"))
                continuation.finish()
            }
        }
    }
}
