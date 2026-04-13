import Cocoa

// Single source of truth for all ripple settings
class RippleConfig {
    var isEnabled: Bool = true
    var rippleColor: NSColor = .white
    var maxRadius: CGFloat = 100
    var animationDuration: CFTimeInterval = 0.7
    var rippleCount: Int = 3
    var dragEffectEnabled: Bool = true
    var lineWidth: CGFloat = 2.5
    var useCircleCursor: Bool = false
    var circleCursorSize: CGFloat = 20
}
