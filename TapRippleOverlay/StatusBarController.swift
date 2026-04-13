import Cocoa

class StatusBarController: NSObject, NSMenuDelegate {

    private var statusItem: NSStatusItem!
    private let eventMonitorManager: EventMonitorManager
    private let overlayWindowController: OverlayWindowController
    private let config: RippleConfig
    private var preferencesWindowController: PreferencesWindowController?

    // Keep a reference so menu items can be updated before display
    private var menu: NSMenu!
    private var toggleItem: NSMenuItem!

    init(eventMonitorManager: EventMonitorManager,
         overlayWindowController: OverlayWindowController,
         config: RippleConfig) {
        self.eventMonitorManager = eventMonitorManager
        self.overlayWindowController = overlayWindowController
        self.config = config
        super.init()
        setupStatusBar()
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "cursorarrow.click.2",
                                   accessibilityDescription: "TapRippleOverlay")
            button.image?.isTemplate = true
        }

        buildMenu()
        statusItem.menu = menu
    }

    private func buildMenu() {
        menu = NSMenu()
        menu.delegate = self

        let settingsItem = NSMenuItem(title: "Open Settings", action: #selector(openPreferences), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        toggleItem = NSMenuItem(title: toggleTitle, action: #selector(toggleOverlay), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit TapRippleOverlay", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    // Refresh dynamic items every time the menu opens
    func menuWillOpen(_ menu: NSMenu) {
        toggleItem.title = toggleTitle
        statusItem.button?.alphaValue = config.isEnabled ? 1.0 : 0.4
    }

    private var toggleTitle: String {
        config.isEnabled ? "Disable Overlay" : "Enable Overlay"
    }

    @objc private func openPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController(config: config)
            preferencesWindowController?.onConfigChanged = { [weak self] in
                self?.applyConfig()
            }
        }
        NSApp.activate(ignoringOtherApps: true)
        preferencesWindowController?.showWindow(nil)
        preferencesWindowController?.window?.makeKeyAndOrderFront(nil)
    }

    @objc private func toggleOverlay() {
        config.isEnabled.toggle()
        applyConfig()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private func applyConfig() {
        overlayWindowController.config = config
        statusItem.button?.alphaValue = config.isEnabled ? 1.0 : 0.4
    }
}
