import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    var statusBarController: StatusBarController!
    var overlayWindowController: OverlayWindowController!
    var eventMonitorManager: EventMonitorManager!
    var config: RippleConfig!
    var mainWindowController: PreferencesWindowController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Regular app — shows in Dock, has a window
        NSApp.setActivationPolicy(.regular)

        config = RippleConfig()

        overlayWindowController = OverlayWindowController()
        overlayWindowController.config = config
        overlayWindowController.setupOverlays()

        eventMonitorManager = EventMonitorManager()
        eventMonitorManager.delegate = overlayWindowController

        statusBarController = StatusBarController(
            eventMonitorManager: eventMonitorManager,
            overlayWindowController: overlayWindowController,
            config: config
        )

        // Open main settings window on launch
        mainWindowController = PreferencesWindowController(config: config)
        mainWindowController.onConfigChanged = { [weak self] in
            self?.overlayWindowController.config = self?.config
        }
        mainWindowController.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)

        eventMonitorManager.startMonitoring()
    }

    func applicationWillTerminate(_ notification: Notification) {
        eventMonitorManager.stopMonitoring()
    }

    // Re-open window if user clicks Dock icon
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows {
            mainWindowController.showWindow(nil)
        }
        return true
    }
}
