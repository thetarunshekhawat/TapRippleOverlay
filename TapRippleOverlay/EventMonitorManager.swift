import Cocoa

protocol EventMonitorDelegate: AnyObject {
    func didDetectClick(at point: NSPoint)
    func didDetectDrag(at point: NSPoint)
    func didDetectMouseMove(at point: NSPoint)
}

class EventMonitorManager {

    weak var delegate: EventMonitorDelegate?

    // Global monitors — fire when events happen outside our app windows
    private var globalMouseDownMonitor: Any?
    private var globalMouseDragMonitor: Any?
    private var globalMouseMoveMonitor: Any?

    // Local monitors — fire when events happen inside our app windows
    private var localMouseDownMonitor: Any?
    private var localMouseDragMonitor: Any?
    private var localMouseMoveMonitor: Any?

    private let dragThrottleInterval: TimeInterval = 0.05
    private var lastDragEventTime: TimeInterval = 0

    var isMonitoring: Bool = false

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        // ── Global monitors (outside app) ──────────────────────────
        globalMouseDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            guard let self = self else { return }
            let pt = self.cocoaPoint(from: event)
            DispatchQueue.main.async { self.delegate?.didDetectClick(at: pt) }
        }

        globalMouseDragMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { [weak self] event in
            guard let self = self else { return }
            let pt = self.cocoaPoint(from: event)
            DispatchQueue.main.async { self.delegate?.didDetectMouseMove(at: pt) }
            let now = Date().timeIntervalSinceReferenceDate
            guard now - self.lastDragEventTime >= self.dragThrottleInterval else { return }
            self.lastDragEventTime = now
            DispatchQueue.main.async { self.delegate?.didDetectDrag(at: pt) }
        }

        globalMouseMoveMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self else { return }
            let pt = self.cocoaPoint(from: event)
            DispatchQueue.main.async { self.delegate?.didDetectMouseMove(at: pt) }
        }

        // ── Local monitors (inside app windows) ────────────────────
        localMouseDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            guard let self = self else { return event }
            let pt = self.cocoaPoint(from: event)
            self.delegate?.didDetectClick(at: pt)
            return event
        }

        localMouseDragMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDragged) { [weak self] event in
            guard let self = self else { return event }
            let pt = self.cocoaPoint(from: event)
            self.delegate?.didDetectMouseMove(at: pt)
            let now = Date().timeIntervalSinceReferenceDate
            if now - self.lastDragEventTime >= self.dragThrottleInterval {
                self.lastDragEventTime = now
                self.delegate?.didDetectDrag(at: pt)
            }
            return event
        }

        localMouseMoveMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self else { return event }
            let pt = self.cocoaPoint(from: event)
            self.delegate?.didDetectMouseMove(at: pt)
            return event
        }
    }

    func stopMonitoring() {
        [globalMouseDownMonitor, globalMouseDragMonitor, globalMouseMoveMonitor,
         localMouseDownMonitor, localMouseDragMonitor, localMouseMoveMonitor]
            .compactMap { $0 }
            .forEach { NSEvent.removeMonitor($0) }
        globalMouseDownMonitor = nil
        globalMouseDragMonitor = nil
        globalMouseMoveMonitor = nil
        localMouseDownMonitor = nil
        localMouseDragMonitor = nil
        localMouseMoveMonitor = nil
        isMonitoring = false
    }

    // Convert from Quartz (top-left origin) to Cocoa (bottom-left origin)
    private func cocoaPoint(from event: NSEvent) -> NSPoint {
        let quartzPt = event.cgEvent?.location ?? CGPoint(x: event.locationInWindow.x, y: event.locationInWindow.y)
        guard let mainScreen = NSScreen.screens.first else { return quartzPt }
        return NSPoint(x: quartzPt.x, y: mainScreen.frame.height - quartzPt.y)
    }
}
