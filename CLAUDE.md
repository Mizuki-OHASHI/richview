# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RichView is a macOS menubar application that renders selected text as LaTeX math formulas. It captures text via global hotkeys, optionally cleans it up using Apple's on-device LLM (FoundationModels), and displays the rendered output in a floating panel using MathJax via WebKit.

## Build & Run

```bash
swift build
swift run RichView
```

No external dependencies — all frameworks are Apple-provided (Cocoa, SwiftUI, WebKit, FoundationModels, ApplicationServices). Requires macOS 26.0+.

Debug/release configurations are in `.vscode/launch.json`.

## Version Control

This project uses **jj (Jujutsu)** with a colocated Git backend. Use `jj` commands for VCS operations, not `git`.

## Architecture

### Data Flow

```
Hotkey (Cmd+Shift+R or E)
  → Text Capture (Accessibility API → clipboard fallback)
  → [Optional] LLM Cleanup (on-device, streaming)
  → WebKit Rendering (MathJax + marked.js)
  → Floating Panel display
```

### State Machine (`AppState`)

`Phase`: idle → capturing → processing → rendered | error

- `Cmd+Shift+R` (keycode 15): capture → LLM cleanup → render
- `Cmd+Shift+E` (keycode 14): capture → direct render (skip LLM)

### Key Modules

- **App/** — `AppDelegate` orchestrates the entire pipeline. `AppState` is the single `@Observable` state container shared across the app.
- **Hotkey/** — `HotkeyManager` installs a system-level `CGEvent` tap. Re-registers on wake from sleep.
- **TextCapture/** — Two strategies: `AccessibilityCapture` (primary, uses AX APIs) and `ClipboardCapture` (fallback, simulates Cmd+C then reads pasteboard, restores original clipboard).
- **LLM/** — `LaTeXCleanupService` streams responses from FoundationModels. `Prompts.swift` contains the system instruction for LaTeX correction.
- **Renderer/** — `MathRenderView` wraps WKWebView. `template.html` loads MathJax (SVG output) and marked.js with 80ms debounced updates via JS bridge.
- **Panel/** — `FloatingPanel` (NSPanel, floating level, HUD style). `PanelManager` handles positioning (centered on cursor screen) and lifecycle.

### Resource Bundling

`Renderer/Resources/` (template.html, mathjax-tex-svg.js, marked.min.js) is copied into the app bundle via Package.swift `.copy()`. Changes to these files require a rebuild.

## Requirements

- Accessibility permission (prompted on first launch via `AXIsProcessTrustedWithOptions`)
- App runs as `.accessory` (no Dock icon, menubar only)
