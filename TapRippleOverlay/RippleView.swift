import Cocoa
import QuartzCore

class RippleView: NSView {

    // Ripple configuration
    var rippleColor: NSColor = .white
    var rippleCount: Int = 3
    var maxRadius: CGFloat = 100
    var animationDuration: CFTimeInterval = 0.7
    var lineWidth: CGFloat = 2.5

    // Circle cursor
    var circleCursorSize: CGFloat = 20 {
        didSet { updateCursorShape() }
    }

    private var cursorLayer: CAShapeLayer?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    override var isOpaque: Bool { return false }

    // MARK: - Circle Cursor

    func showCursorCircle(color: NSColor) {
        guard cursorLayer == nil, let layer = self.layer else { return }

        let cl = CAShapeLayer()
        cl.fillColor = color.withAlphaComponent(0.85).cgColor
        cl.strokeColor = NSColor.clear.cgColor
        cl.lineWidth = 0
        cl.opacity = 1.0
        // Start off-screen
        cl.position = CGPoint(x: -200, y: -200)
        updateCursorShape(layer: cl)
        layer.addSublayer(cl)
        cursorLayer = cl
    }

    func hideCursorCircle() {
        cursorLayer?.removeFromSuperlayer()
        cursorLayer = nil
    }

    func updateCursorColor(_ color: NSColor) {
        cursorLayer?.fillColor = color.withAlphaComponent(0.85).cgColor
    }

    func moveCursor(to point: CGPoint) {
        guard let cl = cursorLayer else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        cl.position = point
        CATransaction.commit()
    }

    private func updateCursorShape(layer cl: CAShapeLayer? = nil) {
        let target = cl ?? cursorLayer
        let r = circleCursorSize / 2
        target?.path = CGPath(ellipseIn: CGRect(x: -r, y: -r, width: circleCursorSize, height: circleCursorSize), transform: nil)
    }

    // MARK: - Ripple

    func triggerRipple(at point: CGPoint, isDrag: Bool = false) {
        guard let layer = self.layer else { return }

        let count = isDrag ? 1 : rippleCount
        let maxR = isDrag ? maxRadius * 0.55 : maxRadius
        let duration = isDrag ? animationDuration * 0.6 : animationDuration
        let initialRadius: CGFloat = isDrag ? 4 : 8

        for i in 0..<count {
            let delay = isDrag ? 0.0 : Double(i) * 0.12
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self, weak layer] in
                guard let self = self, let layer = layer else { return }
                self.addRippleLayer(to: layer, at: point, initialRadius: initialRadius,
                                    maxRadius: maxR, duration: duration, isDrag: isDrag, index: i)
            }
        }
    }

    private func addRippleLayer(to parentLayer: CALayer, at point: CGPoint,
                                 initialRadius: CGFloat, maxRadius: CGFloat,
                                 duration: CFTimeInterval, isDrag: Bool, index: Int) {
        let rippleLayer = CAShapeLayer()

        let initialPath = CGPath(ellipseIn: CGRect(x: point.x - initialRadius, y: point.y - initialRadius,
                                                    width: initialRadius * 2, height: initialRadius * 2), transform: nil)
        let finalPath = CGPath(ellipseIn: CGRect(x: point.x - maxRadius, y: point.y - maxRadius,
                                                  width: maxRadius * 2, height: maxRadius * 2), transform: nil)

        rippleLayer.path = initialPath
        rippleLayer.fillColor = NSColor.clear.cgColor
        rippleLayer.strokeColor = rippleColor.cgColor
        rippleLayer.lineWidth = isDrag ? max(1.0, lineWidth * 0.5) : max(1.0, lineWidth - CGFloat(index) * 0.4)
        rippleLayer.opacity = 1.0

        // Insert below cursor layer so ripples don't cover it
        if let cl = cursorLayer, let idx = parentLayer.sublayers?.firstIndex(of: cl) {
            parentLayer.insertSublayer(rippleLayer, at: UInt32(idx))
        } else {
            parentLayer.addSublayer(rippleLayer)
        }

        let pathAnim = CABasicAnimation(keyPath: "path")
        pathAnim.fromValue = initialPath
        pathAnim.toValue = finalPath
        pathAnim.timingFunction = CAMediaTimingFunction(name: .easeOut)

        let opacityAnim = CABasicAnimation(keyPath: "opacity")
        opacityAnim.fromValue = isDrag ? 0.5 : 0.85
        opacityAnim.toValue = 0.0
        opacityAnim.timingFunction = CAMediaTimingFunction(name: .easeOut)

        let group = CAAnimationGroup()
        group.animations = [pathAnim, opacityAnim]
        group.duration = duration
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false
        group.delegate = RippleAnimationDelegate(layer: rippleLayer)

        rippleLayer.add(group, forKey: "ripple_\(UUID().uuidString)")
    }
}

class RippleAnimationDelegate: NSObject, CAAnimationDelegate {
    private weak var layer: CAShapeLayer?
    init(layer: CAShapeLayer) { self.layer = layer }
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        layer?.removeFromSuperlayer()
    }
}
