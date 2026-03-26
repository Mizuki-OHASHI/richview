import Cocoa
import ApplicationServices

class AccessibilityCapture {
    func captureSelectedText() -> String? {
        guard AXIsProcessTrusted() else {
            print("[RichView] Accessibility not trusted.")
            return nil
        }

        let systemWide = AXUIElementCreateSystemWide()

        // Get focused application
        var focusedAppValue: AnyObject?
        guard AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedApplicationAttribute as CFString,
            &focusedAppValue
        ) == .success else {
            return nil
        }
        let focusedApp = focusedAppValue as! AXUIElement

        // Get focused UI element
        var focusedElementValue: AnyObject?
        guard AXUIElementCopyAttributeValue(
            focusedApp,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElementValue
        ) == .success else {
            return nil
        }
        let focusedElement = focusedElementValue as! AXUIElement

        // Get selected text
        var selectedTextValue: AnyObject?
        guard AXUIElementCopyAttributeValue(
            focusedElement,
            kAXSelectedTextAttribute as CFString,
            &selectedTextValue
        ) == .success else {
            return nil
        }

        return selectedTextValue as? String
    }
}
