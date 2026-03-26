# RichView

A macOS menubar app that renders selected text as beautifully typeset math. Select any text containing LaTeX — in a terminal, browser, PDF, or editor — press a hotkey, and get an instant rendered preview in a floating panel.

An on-device LLM automatically repairs mangled LaTeX (e.g. missing backslashes, broken delimiters) before rendering, so even copy-pasted terminal output comes out right.

## Features

- **Global hotkeys** — works from any application, no context switching
  - `Cmd+Shift+R` — Render with LLM cleanup (fixes broken LaTeX)
  - `Cmd+Shift+E` — Render directly (no LLM, for well-formed input)
- **On-device LLM** — LaTeX repair runs locally via Apple FoundationModels. No network, no API keys, full privacy
- **MathJax rendering** — SVG output with Computer Modern fonts, supports `$...$`, `$$...$$`, `\(...\)`, `\[...\]`
- **Markdown support** — mixed Markdown + LaTeX content renders correctly
- **Floating panel** — HUD-style translucent window, appears at cursor position, stays on top
- **Smart text capture** — Accessibility API with automatic clipboard fallback for broad app compatibility

## Requirements

- macOS 26.0 (Tahoe) or later
- Apple Silicon (required for on-device FoundationModels)
- Accessibility permission (prompted on first launch)

## Build & Run

```bash
swift build
swift run RichView
```

No external dependencies. The app uses only Apple frameworks: Cocoa, SwiftUI, WebKit, FoundationModels, and ApplicationServices.

## Usage

1. Launch RichView — it appears as a `ƒ` icon in the menubar
2. Grant Accessibility permission when prompted
3. Select text containing math in any application
4. Press `Cmd+Shift+R` (with LLM cleanup) or `Cmd+Shift+E` (direct render)
5. A floating panel appears with the rendered output
6. Use the toolbar to toggle LLM, copy cleaned LaTeX, or close (`Esc`)

## Architecture

```
Hotkey → Text Capture → [LLM Cleanup] → MathJax Render → Floating Panel
```

| Module | Role |
|---|---|
| `App/` | SwiftUI lifecycle, `@Observable` state machine (idle → capturing → processing → rendered) |
| `Hotkey/` | System-level `CGEvent` tap for global keyboard shortcuts |
| `TextCapture/` | Dual strategy: Accessibility API primary, simulated Cmd+C fallback |
| `LLM/` | On-device streaming inference via FoundationModels for LaTeX repair |
| `Renderer/` | WKWebView with bundled MathJax 3 (SVG) + marked.js, debounced updates |
| `Panel/` | NSPanel floating window with HUD appearance, positioned at cursor |

## License

All rights reserved.
