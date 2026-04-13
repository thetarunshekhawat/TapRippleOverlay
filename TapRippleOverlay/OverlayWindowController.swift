import Cocoa

class OverlayWindowController: NSObject, EventMonitorDelegate {

    private var overlayWindows: [NSWindow] = []
    private var rippleViews: [NSScreen: RippleView] = [:]

    private var circleCursorActive: Bool = false
    // Local monitor that intercepts AppKit cursor updates and swaps in transparent cursor
    private var cursorUpdateMonitor: Any?
    // Transparent 1×1 cursor — built once and reused
    private lazy var transparentCursor: NSCursor = {
        let img = NSImage(size: NSSize(width: 1, height: 1))
        img.lockFocus()
        NSColor.clear.set()
        NSRect(x: 0, y: 0, width: 1, height: 1).fill()
        img.unlockFocus()
        return NSCursor(image: img, hotSpot: .zero)
    }()

    var config: RippleConfig! {
        didSet { applyConfig() }
    }

    func setupOverlays() {
        teardownOverlays()
        for screen in NSScreen.screens {
            createOverlayWindow(for: screen)
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    private func teardownOverlays() {
        overlayWindows.forEach { $0.orderOut(nil) }
        overlayWindows.removeAll()
        rippleViews.removeAll()
    }

    private func createOverlayWindow(for screen: NSScreen) {
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: screen
        )
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)))
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false

        let rippleView = RippleView(frame: CGRect(origin: .zero, size: screen.frame.size))
        applyConfig(to: rippleView)
        window.contentView = rippleView

        rippleViews[screen] = rippleView
        overlayWindows.append(window)
        window.orderFrontRegardless()
    }

    private func applyConfig() {
        guard let config = config else { return }
        rippleViews.values.forEach { applyConfig(to: $0) }

        if config.useCircleCursor && !circleCursorActive {
            enableCircleCursor()
        } else if !config.useCircleCursor && circleCursorActive {
            disableCircleCursor()
        } else if config.useCircleCursor && circleCursorActive {
            rippleViews.values.forEach {
                $0.circleCursorSize = config.circleCursorSize
                $0.updateCursorColor(config.rippleColor)
            }
        }
    }

    private func applyConfig(to view: RippleView) {
        guard let config = config else { return }
        view.rippleColor = config.rippleColor
        view.maxRadius = config.maxRadius
        view.animationDuration = config.animationDuration
        view.rippleCount = config.rippleCount
        view.lineWidth = config.lineWidth
        view.circleCursorSize = config.circleCursorSize
    }

    // MARK: - Circle Cursor

    private func enableCircleCursor() {
        circleCursorActive = true

        // Hide system cursor globally (covers areas outside our app)
        CGDisplayHideCursor(CGMainDisplayID())
        // Set transparent cursor immediately for within-app areas
        transparentCursor.set()
        // Intercept AppKit's cursor update events so it can't restore the arrow
        cursorUpdateMonitor = NSEvent.addLocalMonitorForEvents(matching: .cursorUpdate) { [weak self] event in
            self?.transparentCursor.set()
            return event   // still pass it through so AppKit bookkeeping is fine
        }
        // Disable cursor rect management on all app windows
        NSApp.windows.forEach { $0.disableCursorRects() }

        rippleViews.values.forEach {
            $0.circleCursorSize = config.circleCursorSize
            $0.showCursorCircle(color: config.rippleColor)
        }

        // Seed initial position
        let mouse = NSEvent.mouseLocation
        didDetectMouseMove(at: mouse)
    }

    private func disableCircleCursor() {
        circleCursorActive = false

        if let monitor = cursorUpdateMonitor {
            NSEvent.removeMonitor(monitor)
            cursorUpdateMonitor = nil
        }
        NSApp.windows.forEach { $0.enableCursorRects() }
        CGDisplayShowCursor(CGMainDisplayID())
        NSCursor.arrow.set()

        rippleViews.values.forEach { $0.hideCursorCircle() }
    }

    @objc private func screensChanged() {
        let wasActive = circleCursorActive
        if wasActive { disableCircleCursor() }
        setupOverlays()
        if wasActive { enableCircleCursor() }
    }

    // MARK: - EventMonitorDelegate

    func didDetectClick(at point: NSPoint) {
        guard let config = config, config.isEnabled else { return }
        guard let (_, rippleView, localPoint) = resolveScreen(for: point) else { return }
        applyConfig(to: rippleView)
        rippleView.triggerRipple(at: localPoint, isDrag: false)
    }

    func didDetectDrag(at point: NSPoint) {
        guard let config = config, config.isEnabled, config.dragEffectEnabled else { return }
        guard let (_, rippleView, localPoint) = resolveScreen(for: point) else { return }
        applyConfig(to: rippleView)
        rippleView.triggerRipple(at: localPoint, isDrag: true)
    }

    func didDetectMouseMove(at point: NSPoint) {
        guard circleCursorActive else { return }
        for (screen, rippleView) in rippleViews {
            if screen.frame.contains(point) {
                let localX = point.x - screen.frame.origin.x
                let localY = point.y - screen.frame.origin.y
                rippleView.moveCursor(to: CGPoint(x: localX, y: localY))
            }
        }
    }

    private func resolveScreen(for globalPoint: NSPoint) -> (NSScreen, RippleView, CGPoint)? {
        for screen in NSScreen.screens {
            if screen.frame.contains(globalPoint) {
                guard let rippleView = rippleViews[screen] else { continue }
                let localX = globalPoint.x - screen.frame.origin.x
                let localY = globalPoint.y - screen.frame.origin.y
                return (screen, rippleView, CGPoint(x: localX, y: localY))
            }
        }
        return nil
    }

    deinit {
        if circleCursorActive { disableCircleCursor() }
        NotificationCenter.default.removeObserver(self)
    }
}
