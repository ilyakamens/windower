import AppKit
@preconcurrency import ApplicationServices
import WindowGeometry

@MainActor
final class WindowManager {
  static var hasAccess: Bool { AXIsProcessTrusted() }

  static func requestAccess() {
    let options =
      [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
    _ = AXIsProcessTrustedWithOptions(options)
  }

  func perform(_ action: WindowAction, application: NSRunningApplication?) throws {
    guard Self.hasAccess else { throw WindowError("Enable Accessibility access for Windower.") }
    guard let application,
      application.processIdentifier != ProcessInfo.processInfo.processIdentifier
    else {
      throw WindowError("No active window.")
    }
    let app = AXUIElementCreateApplication(application.processIdentifier)
    AXUIElementSetMessagingTimeout(app, 0.5)
    guard let value = attribute(app, kAXFocusedWindowAttribute),
      CFGetTypeID(value) == AXUIElementGetTypeID()
    else {
      throw WindowError("No active window.")
    }
    let window = unsafeDowncast(value, to: AXUIElement.self)
    if attribute(window, "AXFullScreen") as? Bool == true {
      throw WindowError("Exit full screen before moving this window.")
    }
    guard let current = frame(window) else {
      throw WindowError("Cannot read this window’s position.")
    }
    let screens = NSScreen.screens
    guard let primary = screens.first else { throw WindowError("No display available.") }
    let frames = screens.map {
      WindowGeometry.accessibilityRect($0.frame, primaryHeight: primary.frame.height)
    }
    guard let index = WindowGeometry.screenIndex(for: current, screens: frames) else { return }
    let bounds = WindowGeometry.accessibilityRect(
      screens[index].visibleFrame, primaryHeight: primary.frame.height)
    let target = WindowGeometry.target(for: action, in: bounds)
    var movable: DarwinBoolean = false
    var resizable: DarwinBoolean = false
    AXUIElementIsAttributeSettable(window, kAXPositionAttribute as CFString, &movable)
    AXUIElementIsAttributeSettable(window, kAXSizeAttribute as CFString, &resizable)
    guard movable.boolValue else { throw WindowError("This window cannot be moved.") }
    guard resizable.boolValue else { throw WindowError("This window cannot be resized.") }

    // Move between display bounds before resizing, then re-anchor using the accepted size.
    try setPosition(target.origin, on: window)
    try setSize(target.size, on: window)
    let actualSize = frame(window)?.size ?? target.size
    try setPosition(WindowGeometry.position(for: action, size: actualSize, in: bounds), on: window)
  }

  private func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else {
      return nil
    }
    return value
  }

  private func frame(_ window: AXUIElement) -> CGRect? {
    guard let position = attribute(window, kAXPositionAttribute),
      let size = attribute(window, kAXSizeAttribute),
      CFGetTypeID(position) == AXValueGetTypeID(), CFGetTypeID(size) == AXValueGetTypeID()
    else { return nil }
    var point = CGPoint.zero
    var dimensions = CGSize.zero
    guard AXValueGetValue(unsafeDowncast(position, to: AXValue.self), .cgPoint, &point),
      AXValueGetValue(unsafeDowncast(size, to: AXValue.self), .cgSize, &dimensions)
    else { return nil }
    return CGRect(origin: point, size: dimensions)
  }

  private func setPosition(_ point: CGPoint, on window: AXUIElement) throws {
    var point = point
    guard let value = AXValueCreate(.cgPoint, &point) else { return }
    let result = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, value)
    guard result == .success else {
      throw WindowError("Could not move this window (\(result.rawValue)).")
    }
  }

  private func setSize(_ size: CGSize, on window: AXUIElement) throws {
    var size = size
    guard let value = AXValueCreate(.cgSize, &size) else { return }
    let result = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, value)
    guard result == .success else {
      throw WindowError("Could not resize this window (\(result.rawValue)).")
    }
  }
}

struct WindowError: LocalizedError {
  let message: String
  init(_ message: String) { self.message = message }
  var errorDescription: String? { message }
}
