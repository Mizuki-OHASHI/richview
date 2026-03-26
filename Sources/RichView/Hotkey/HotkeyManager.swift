import Cocoa

class HotkeyManager {
    var onHotkeyWithLLM: (() -> Void)?
    var onHotkeyWithoutLLM: (() -> Void)?

    fileprivate var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    func register() {
        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
        let refcon = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: hotkeyCallback,
            userInfo: refcon
        ) else {
            print("[RichView] Failed to create event tap. Grant Accessibility permission in System Settings.")
            return
        }

        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func unregister() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    deinit {
        unregister()
    }
}

private func hotkeyCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon = refcon else { return Unmanaged.passRetained(event) }
    let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()

    // Re-enable tap if it was disabled by timeout
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap = manager.eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return Unmanaged.passRetained(event)
    }

    guard type == .keyDown else {
        return Unmanaged.passRetained(event)
    }

    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    let flags = event.flags
    let hasCmd = flags.contains(.maskCommand)
    let hasShift = flags.contains(.maskShift)
    let hasCtrl = flags.contains(.maskControl)
    let hasOpt = flags.contains(.maskAlternate)

    // Cmd+Shift+R (R = keycode 15): with LLM cleanup
    if keyCode == 15 && hasCmd && hasShift && !hasCtrl && !hasOpt {
        DispatchQueue.main.async { manager.onHotkeyWithLLM?() }
        return nil // consume the event
    }

    // Cmd+Shift+D (D = keycode 2): direct render without LLM
    if keyCode == 2 && hasCmd && hasShift && !hasCtrl && !hasOpt {
        DispatchQueue.main.async { manager.onHotkeyWithoutLLM?() }
        return nil
    }

    return Unmanaged.passRetained(event)
}
