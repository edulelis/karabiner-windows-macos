import AppKit
import ApplicationServices
import Foundation

private let accessibilityURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!

@discardableResult
private func requestAccessibility(prompt: Bool) -> Bool {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
    return AXIsProcessTrustedWithOptions(options)
}

private func openAccessibilitySettings() {
    NSWorkspace.shared.open(accessibilityURL)
}

private func axString(_ element: AXUIElement, _ attribute: CFString) -> String? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else {
        return nil
    }
    return value as? String
}

private func finderFocusedElement() -> AXUIElement? {
    guard let finder = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == "com.apple.finder" }) else {
        return nil
    }

    let finderElement = AXUIElementCreateApplication(finder.processIdentifier)
    var focusedValue: CFTypeRef?

    guard AXUIElementCopyAttributeValue(finderElement, kAXFocusedUIElementAttribute as CFString, &focusedValue) == .success,
          let focusedElement = focusedValue else {
        return nil
    }

    return (focusedElement as! AXUIElement)
}

private func finderIsEditingText() -> Bool {
    guard let focusedElement = finderFocusedElement() else {
        return false
    }

    let role = axString(focusedElement, kAXRoleAttribute as CFString)
    let subrole = axString(focusedElement, kAXSubroleAttribute as CFString)

    return role == kAXTextFieldRole as String ||
        role == "AXTextArea" ||
        role == "AXComboBox" ||
        subrole == "AXSearchField"
}

private func postKey(_ keyCode: CGKeyCode, flags: CGEventFlags = []) {
    let source = CGEventSource(stateID: .hidSystemState)

    let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
    keyDown?.flags = flags
    keyDown?.post(tap: .cghidEventTap)

    let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
    keyUp?.flags = flags
    keyUp?.post(tap: .cghidEventTap)
}

let arguments = Set(CommandLine.arguments.dropFirst())

if arguments.contains("--prompt") {
    if !requestAccessibility(prompt: true) {
        openAccessibilitySettings()
        exit(2)
    }
    exit(0)
}

guard requestAccessibility(prompt: true) else {
    openAccessibilitySettings()
    exit(2)
}

if finderIsEditingText() {
    postKey(51)
} else {
    postKey(126, flags: .maskCommand)
}
