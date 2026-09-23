import AppKit
import Carbon
import WindowGeometry

@MainActor
final class HotKeys {
  private var references: [EventHotKeyRef] = []
  private var handler: EventHandlerRef?
  var onAction: ((WindowAction) -> Void)?
  private(set) var failures: [String] = []
  static let signature: OSType = 0x574E_4452  // WNDR

  func register() {
    var eventType = EventTypeSpec(
      eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
    let status = InstallEventHandler(
      GetApplicationEventTarget(),
      { _, event, context in
        guard let event, let context else { return OSStatus(eventNotHandledErr) }
        var identifier = EventHotKeyID()
        let result = GetEventParameter(
          event, EventParamName(kEventParamDirectObject),
          EventParamType(typeEventHotKeyID), nil,
          MemoryLayout<EventHotKeyID>.size, nil, &identifier)
        guard result == noErr, identifier.signature == HotKeys.signature,
          let action = WindowAction(rawValue: Int(identifier.id))
        else {
          return OSStatus(eventNotHandledErr)
        }
        MainActor.assumeIsolated {
          let manager = Unmanaged<HotKeys>.fromOpaque(context).takeUnretainedValue()
          manager.onAction?(action)
        }
        return noErr
      }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &handler)
    guard status == noErr else {
      failures = ["Could not listen for shortcuts (\(status))."]
      return
    }
    for action in WindowAction.allCases {
      var reference: EventHotKeyRef?
      let result = RegisterEventHotKey(
        action.keyCode, UInt32(controlKey | optionKey | cmdKey),
        EventHotKeyID(signature: Self.signature, id: UInt32(action.rawValue)),
        GetApplicationEventTarget(), 0, &reference)
      if result == noErr, let reference {
        references.append(reference)
      } else {
        failures.append(
          "\(action.title) shortcut unavailable (\(result)). Quit any app using it and reopen Windower."
        )
      }
    }
  }

  func unregister() {
    for reference in references { UnregisterEventHotKey(reference) }
    references.removeAll()
    if let handler { RemoveEventHandler(handler) }
    handler = nil
  }
}

extension WindowAction {
  var keyCode: UInt32 {
    switch self {
    case .left: UInt32(kVK_LeftArrow)
    case .right: UInt32(kVK_RightArrow)
    case .top: UInt32(kVK_UpArrow)
    case .bottom: UInt32(kVK_DownArrow)
    case .center: UInt32(kVK_ANSI_C)
    case .maximize: UInt32(kVK_ANSI_M)
    }
  }

  var keyEquivalent: String {
    switch self {
    case .left: String(UnicodeScalar(NSLeftArrowFunctionKey)!)
    case .right: String(UnicodeScalar(NSRightArrowFunctionKey)!)
    case .top: String(UnicodeScalar(NSUpArrowFunctionKey)!)
    case .bottom: String(UnicodeScalar(NSDownArrowFunctionKey)!)
    case .center: "c"
    case .maximize: "m"
    }
  }
}
