import AppKit
import ServiceManagement
import WindowGeometry

@main
@MainActor
struct WindowerApp {
  static func main() {
    let application = NSApplication.shared
    let delegate = AppDelegate()
    application.delegate = delegate
    application.setActivationPolicy(.accessory)
    withExtendedLifetime(delegate) { application.run() }
  }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
  private var statusItem: NSStatusItem!
  private let menu = NSMenu()
  private let hotKeys = HotKeys()
  private let windows = WindowManager()
  private var selectedApplication: NSRunningApplication?
  private var lastError: String?
  private let accessItem = NSMenuItem(
    title: "Enable Accessibility…", action: #selector(openAccessibility), keyEquivalent: "")
  private let loginItem = NSMenuItem(
    title: "Launch at Login", action: #selector(toggleLogin), keyEquivalent: "")
  private let loginSettingsItem = NSMenuItem(
    title: "Approve Launch at Login…", action: #selector(openLoginSettings), keyEquivalent: "")
  private let errorItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
  private var actionItems: [NSMenuItem] = []

  func applicationDidFinishLaunching(_ notification: Notification) {
    // Avoid duplicate app copies competing for the same global shortcuts.
    if let identifier = Bundle.main.bundleIdentifier,
      NSRunningApplication.runningApplications(withBundleIdentifier: identifier).count > 1
    {
      NSApp.terminate(nil)
      return
    }
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    let image = NSImage(
      systemSymbolName: "rectangle.split.2x2", accessibilityDescription: "Windower")
    image?.isTemplate = true
    statusItem.button?.image = image
    statusItem.button?.toolTip = "Windower"
    if image == nil { statusItem.button?.title = "W" }
    menu.delegate = self
    menu.autoenablesItems = false
    accessItem.target = self
    menu.addItem(accessItem)
    for action in WindowAction.allCases {
      let item = NSMenuItem(
        title: action.title, action: #selector(runMenuAction(_:)),
        keyEquivalent: action.keyEquivalent)
      item.keyEquivalentModifierMask = [.control, .option, .command]
      item.tag = action.rawValue
      item.target = self
      actionItems.append(item)
      menu.addItem(item)
    }
    menu.addItem(.separator())
    errorItem.isEnabled = false
    errorItem.isHidden = true
    menu.addItem(errorItem)
    loginItem.target = self
    menu.addItem(loginItem)
    loginSettingsItem.target = self
    menu.addItem(loginSettingsItem)
    menu.addItem(.separator())
    let quit = NSMenuItem(title: "Quit Windower", action: #selector(quit), keyEquivalent: "q")
    quit.target = self
    menu.addItem(quit)
    statusItem.menu = menu
    hotKeys.onAction = { [weak self] action in
      self?.perform(action, application: NSWorkspace.shared.frontmostApplication)
    }
    hotKeys.register()
    if !hotKeys.failures.isEmpty { lastError = hotKeys.failures.joined(separator: "\n") }
    enableLoginOnFirstLaunch()
    refreshMenu()
    let defaults = UserDefaults.standard
    if !WindowManager.hasAccess && !defaults.bool(forKey: "didRequestAccessibility") {
      defaults.set(true, forKey: "didRequestAccessibility")
      WindowManager.requestAccess()
    }
  }

  func applicationWillTerminate(_ notification: Notification) { hotKeys.unregister() }

  func menuWillOpen(_ menu: NSMenu) {
    selectedApplication = NSWorkspace.shared.frontmostApplication
    refreshMenu()
  }

  private func refreshMenu() {
    accessItem.isHidden = WindowManager.hasAccess
    for item in actionItems { item.isEnabled = WindowManager.hasAccess }
    let status = SMAppService.mainApp.status
    loginItem.state = status == .enabled ? .on : (status == .requiresApproval ? .mixed : .off)
    loginSettingsItem.isHidden = status != .requiresApproval
    errorItem.title = lastError ?? ""
    errorItem.isHidden = lastError == nil
    statusItem.button?.toolTip = lastError.map { "Windower: \($0)" } ?? "Windower"
  }

  private func perform(_ action: WindowAction, application: NSRunningApplication?) {
    do {
      try windows.perform(action, application: application)
      lastError = hotKeys.failures.isEmpty ? nil : hotKeys.failures.joined(separator: "\n")
    } catch {
      lastError = error.localizedDescription
      NSSound.beep()
    }
    refreshMenu()
  }

  @objc private func runMenuAction(_ sender: NSMenuItem) {
    guard let action = WindowAction(rawValue: sender.tag) else { return }
    let application = selectedApplication
    // Let menu tracking end before changing another app's focused window.
    DispatchQueue.main.async { [weak self] in self?.perform(action, application: application) }
  }

  @objc private func openAccessibility() {
    WindowManager.requestAccess()
    if let url = URL(
      string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    {
      NSWorkspace.shared.open(url)
    }
  }

  private func enableLoginOnFirstLaunch() {
    let defaults = UserDefaults.standard
    guard !defaults.bool(forKey: "didConfigureLogin") else { return }
    do {
      try SMAppService.mainApp.register()
      defaults.set(true, forKey: "didConfigureLogin")
    } catch {
      lastError = "Could not enable Launch at Login: \(error.localizedDescription)"
    }
  }

  @objc private func toggleLogin() {
    do {
      if SMAppService.mainApp.status == .enabled || SMAppService.mainApp.status == .requiresApproval
      {
        try SMAppService.mainApp.unregister()
      } else {
        try SMAppService.mainApp.register()
      }
      UserDefaults.standard.set(true, forKey: "didConfigureLogin")
      lastError = hotKeys.failures.isEmpty ? nil : hotKeys.failures.joined(separator: "\n")
    } catch {
      lastError = "Could not update Launch at Login: \(error.localizedDescription)"
    }
    refreshMenu()
  }

  @objc private func openLoginSettings() { SMAppService.openSystemSettingsLoginItems() }
  @objc private func quit() { NSApp.terminate(nil) }
}
