import Cocoa
import QuartzCore

class PreferencesWindowController: NSWindowController {

    var config: RippleConfig!
    var onConfigChanged: (() -> Void)?

    private var powerToggle: NSButton!
    private var powerLabel: NSTextField!
    private var colorWell: NSColorWell!
    private var sizeSlider: NSSlider!
    private var sizeValueLabel: NSTextField!
    private var durationSlider: NSSlider!
    private var durationValueLabel: NSTextField!
    private var ringCountStepper: NSStepper!
    private var ringCountLabel: NSTextField!
    private var lineWidthSlider: NSSlider!
    private var lineWidthValueLabel: NSTextField!
    private var dragToggle: NSButton!
    private var circleCursorToggle: NSButton!
    private var cursorSizeSlider: NSSlider!
    private var cursorSizeValueLabel: NSTextField!
    private var cursorSizeRow: NSView!
    private var previewView: PreviewRippleView!

    convenience init(config: RippleConfig) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "TapRippleOverlay"
        window.center()
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = NSColor(calibratedWhite: 0.12, alpha: 1.0)
        window.setFrameAutosaveName("TapRippleOverlayMain")

        self.init(window: window)
        self.config = config
        buildUI()
    }

    private func buildUI() {
        guard let contentView = window?.contentView else { return }
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor(calibratedWhite: 0.12, alpha: 1.0).cgColor

        // ── Header ──────────────────────────────────────────────
        let headerView = NSView(frame: .zero)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.wantsLayer = true
        headerView.layer?.backgroundColor = NSColor(calibratedWhite: 0.08, alpha: 1.0).cgColor
        contentView.addSubview(headerView)

        let appIcon = NSImageView()
        appIcon.translatesAutoresizingMaskIntoConstraints = false
        appIcon.image = NSImage(systemSymbolName: "cursorarrow.click.2", accessibilityDescription: nil)
        appIcon.contentTintColor = .white
        appIcon.imageScaling = .scaleProportionallyUpOrDown
        headerView.addSubview(appIcon)

        let titleLabel = makeLabel("TapRippleOverlay", size: 18, bold: true, color: .white)
        let subtitleLabel = makeLabel("Global Click Visualizer", size: 11, bold: false, color: NSColor(calibratedWhite: 0.6, alpha: 1))
        headerView.addSubview(titleLabel)
        headerView.addSubview(subtitleLabel)

        // ── Power toggle ─────────────────────────────────────────
        powerToggle = NSButton(checkboxWithTitle: "", target: self, action: #selector(powerToggled))
        powerToggle.translatesAutoresizingMaskIntoConstraints = false
        powerToggle.setButtonType(.onOff)
        powerToggle.bezelStyle = .rounded
        powerToggle.state = config.isEnabled ? .on : .off
        headerView.addSubview(powerToggle)

        powerLabel = makeLabel(config.isEnabled ? "ON" : "OFF", size: 13, bold: true,
                               color: config.isEnabled ? .systemGreen : NSColor(calibratedWhite: 0.4, alpha: 1))
        headerView.addSubview(powerLabel)

        // ── Live preview ─────────────────────────────────────────
        let previewContainer = NSView(frame: .zero)
        previewContainer.translatesAutoresizingMaskIntoConstraints = false
        previewContainer.wantsLayer = true
        previewContainer.layer?.backgroundColor = NSColor(calibratedWhite: 0.07, alpha: 1.0).cgColor
        previewContainer.layer?.cornerRadius = 12
        previewContainer.layer?.borderWidth = 1
        previewContainer.layer?.borderColor = NSColor(calibratedWhite: 0.25, alpha: 1).cgColor
        contentView.addSubview(previewContainer)

        let previewLabel = makeLabel("LIVE PREVIEW  —  click inside to test", size: 10, bold: false,
                                     color: NSColor(calibratedWhite: 0.4, alpha: 1))
        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        previewContainer.addSubview(previewLabel)

        previewView = PreviewRippleView(frame: .zero)
        previewView.translatesAutoresizingMaskIntoConstraints = false
        previewView.config = config
        previewContainer.addSubview(previewView)

        // ── Settings card ─────────────────────────────────────────
        let card = NSView(frame: .zero)
        card.translatesAutoresizingMaskIntoConstraints = false
        card.wantsLayer = true
        card.layer?.backgroundColor = NSColor(calibratedWhite: 0.18, alpha: 1).cgColor
        card.layer?.cornerRadius = 12
        card.layer?.borderWidth = 1
        card.layer?.borderColor = NSColor(calibratedWhite: 0.28, alpha: 1).cgColor
        contentView.addSubview(card)

        let cardPad: CGFloat = 16
        let rowH: CGFloat = 36

        // ── Color ─────────────────────────────────────────────────
        let colorLabel = makeLabel("Ripple Color", size: 12, bold: false, color: NSColor(calibratedWhite: 0.7, alpha: 1))
        colorWell = NSColorWell(style: .minimal)
        colorWell.translatesAutoresizingMaskIntoConstraints = false
        colorWell.color = config.rippleColor
        colorWell.target = self
        colorWell.action = #selector(colorChanged)
        colorWell.wantsLayer = true
        colorWell.layer?.cornerRadius = 6
        card.addSubview(colorLabel)
        card.addSubview(colorWell)
        addSeparator(to: card, below: colorWell, insets: cardPad)

        // ── Ripple Size ───────────────────────────────────────────
        let sizeLabel = makeLabel("Ripple Size", size: 12, bold: false, color: NSColor(calibratedWhite: 0.7, alpha: 1))
        sizeSlider = NSSlider(value: Double(config.maxRadius), minValue: 30, maxValue: 180,
                              target: self, action: #selector(sizeChanged))
        sizeSlider.translatesAutoresizingMaskIntoConstraints = false
        sizeSlider.isContinuous = true
        sizeValueLabel = makeLabel("\(Int(config.maxRadius))px", size: 11, bold: false,
                                   color: NSColor(calibratedWhite: 0.5, alpha: 1))
        sizeValueLabel.alignment = .right
        card.addSubview(sizeLabel)
        card.addSubview(sizeSlider)
        card.addSubview(sizeValueLabel)
        addSeparator(to: card, below: sizeSlider, insets: cardPad)

        // ── Ring Width ────────────────────────────────────────────
        let lineWidthLabel = makeLabel("Ring Width", size: 12, bold: false, color: NSColor(calibratedWhite: 0.7, alpha: 1))
        lineWidthSlider = NSSlider(value: Double(config.lineWidth), minValue: 0.5, maxValue: 10.0,
                                   target: self, action: #selector(lineWidthChanged))
        lineWidthSlider.translatesAutoresizingMaskIntoConstraints = false
        lineWidthSlider.isContinuous = true
        lineWidthValueLabel = makeLabel(String(format: "%.1fpx", config.lineWidth), size: 11, bold: false,
                                        color: NSColor(calibratedWhite: 0.5, alpha: 1))
        lineWidthValueLabel.alignment = .right
        card.addSubview(lineWidthLabel)
        card.addSubview(lineWidthSlider)
        card.addSubview(lineWidthValueLabel)
        addSeparator(to: card, below: lineWidthSlider, insets: cardPad)

        // ── Animation Speed ───────────────────────────────────────
        let durLabel = makeLabel("Animation Speed", size: 12, bold: false, color: NSColor(calibratedWhite: 0.7, alpha: 1))
        durationSlider = NSSlider(value: config.animationDuration, minValue: 0.3, maxValue: 1.5,
                                  target: self, action: #selector(durationChanged))
        durationSlider.translatesAutoresizingMaskIntoConstraints = false
        durationSlider.isContinuous = true
        durationValueLabel = makeLabel(String(format: "%.1fs", config.animationDuration), size: 11,
                                       bold: false, color: NSColor(calibratedWhite: 0.5, alpha: 1))
        durationValueLabel.alignment = .right
        card.addSubview(durLabel)
        card.addSubview(durationSlider)
        card.addSubview(durationValueLabel)
        addSeparator(to: card, below: durationSlider, insets: cardPad)

        // ── Ring Count ────────────────────────────────────────────
        let ringLabel = makeLabel("Ring Count", size: 12, bold: false, color: NSColor(calibratedWhite: 0.7, alpha: 1))
        ringCountStepper = NSStepper()
        ringCountStepper.translatesAutoresizingMaskIntoConstraints = false
        ringCountStepper.minValue = 1
        ringCountStepper.maxValue = 6
        ringCountStepper.increment = 1
        ringCountStepper.intValue = Int32(config.rippleCount)
        ringCountStepper.valueWraps = false
        ringCountStepper.target = self
        ringCountStepper.action = #selector(ringCountChanged)
        ringCountLabel = makeLabel("\(config.rippleCount) ring\(config.rippleCount == 1 ? "" : "s")", size: 11,
                                   bold: false, color: NSColor(calibratedWhite: 0.5, alpha: 1))
        ringCountLabel.alignment = .right
        card.addSubview(ringLabel)
        card.addSubview(ringCountStepper)
        card.addSubview(ringCountLabel)
        addSeparator(to: card, below: ringCountStepper, insets: cardPad)

        // ── Drag Trail ────────────────────────────────────────────
        let dragLabel = makeLabel("Drag Trail Effect", size: 12, bold: false, color: NSColor(calibratedWhite: 0.7, alpha: 1))
        dragToggle = NSButton(checkboxWithTitle: "", target: self, action: #selector(dragToggled))
        dragToggle.translatesAutoresizingMaskIntoConstraints = false
        dragToggle.state = config.dragEffectEnabled ? .on : .off
        card.addSubview(dragLabel)
        card.addSubview(dragToggle)
        addSeparator(to: card, below: dragToggle, insets: cardPad)

        // ── Circle Cursor ─────────────────────────────────────────
        let cursorToggleLabel = makeLabel("Circle Cursor", size: 12, bold: false, color: NSColor(calibratedWhite: 0.7, alpha: 1))
        circleCursorToggle = NSButton(checkboxWithTitle: "", target: self, action: #selector(circleCursorToggled))
        circleCursorToggle.translatesAutoresizingMaskIntoConstraints = false
        circleCursorToggle.state = config.useCircleCursor ? .on : .off
        card.addSubview(cursorToggleLabel)
        card.addSubview(circleCursorToggle)

        // Cursor size row (shown/hidden based on toggle)
        cursorSizeRow = NSView()
        cursorSizeRow.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(cursorSizeRow)

        let cursorSizeLabel = makeLabel("Cursor Size", size: 12, bold: false, color: NSColor(calibratedWhite: 0.7, alpha: 1))
        cursorSizeSlider = NSSlider(value: Double(config.circleCursorSize), minValue: 8, maxValue: 60,
                                    target: self, action: #selector(cursorSizeChanged))
        cursorSizeSlider.translatesAutoresizingMaskIntoConstraints = false
        cursorSizeSlider.isContinuous = true
        cursorSizeValueLabel = makeLabel("\(Int(config.circleCursorSize))px", size: 11, bold: false,
                                         color: NSColor(calibratedWhite: 0.5, alpha: 1))
        cursorSizeValueLabel.alignment = .right
        cursorSizeRow.addSubview(cursorSizeLabel)
        cursorSizeRow.addSubview(cursorSizeSlider)
        cursorSizeRow.addSubview(cursorSizeValueLabel)

        NSLayoutConstraint.activate([
            cursorSizeLabel.leadingAnchor.constraint(equalTo: cursorSizeRow.leadingAnchor),
            cursorSizeLabel.topAnchor.constraint(equalTo: cursorSizeRow.topAnchor),
            cursorSizeSlider.leadingAnchor.constraint(equalTo: cursorSizeRow.leadingAnchor),
            cursorSizeSlider.trailingAnchor.constraint(equalTo: cursorSizeValueLabel.leadingAnchor, constant: -8),
            cursorSizeSlider.topAnchor.constraint(equalTo: cursorSizeLabel.bottomAnchor, constant: 4),
            cursorSizeSlider.bottomAnchor.constraint(equalTo: cursorSizeRow.bottomAnchor),
            cursorSizeValueLabel.trailingAnchor.constraint(equalTo: cursorSizeRow.trailingAnchor),
            cursorSizeValueLabel.centerYAnchor.constraint(equalTo: cursorSizeSlider.centerYAnchor),
            cursorSizeValueLabel.widthAnchor.constraint(equalToConstant: 48),
        ])

        cursorSizeRow.alphaValue = config.useCircleCursor ? 1.0 : 0.35

        // ── Quit ──────────────────────────────────────────────────
        let quitBtn = NSButton(title: "Quit App", target: self, action: #selector(quitApp))
        quitBtn.translatesAutoresizingMaskIntoConstraints = false
        quitBtn.bezelStyle = .rounded
        quitBtn.contentTintColor = NSColor.systemRed
        contentView.addSubview(quitBtn)

        // ── Auto Layout ───────────────────────────────────────────
        NSLayoutConstraint.activate([
            // Header
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 80),

            appIcon.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            appIcon.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            appIcon.widthAnchor.constraint(equalToConstant: 36),
            appIcon.heightAnchor.constraint(equalToConstant: 36),

            titleLabel.leadingAnchor.constraint(equalTo: appIcon.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),

            powerLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            powerLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor, constant: 8),
            powerToggle.trailingAnchor.constraint(equalTo: powerLabel.leadingAnchor, constant: -6),
            powerToggle.centerYAnchor.constraint(equalTo: powerLabel.centerYAnchor),

            // Preview
            previewContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            previewContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            previewContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            previewContainer.heightAnchor.constraint(equalToConstant: 130),

            previewLabel.centerXAnchor.constraint(equalTo: previewContainer.centerXAnchor),
            previewLabel.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: -8),
            previewView.topAnchor.constraint(equalTo: previewContainer.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: previewLabel.topAnchor, constant: -4),

            // Card
            card.topAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: 16),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Color row
            colorLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: cardPad),
            colorLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: cardPad),
            colorLabel.centerYAnchor.constraint(equalTo: colorWell.centerYAnchor),
            colorWell.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -cardPad),
            colorWell.topAnchor.constraint(equalTo: card.topAnchor, constant: cardPad - 2),
            colorWell.widthAnchor.constraint(equalToConstant: 44),
            colorWell.heightAnchor.constraint(equalToConstant: 28),

            // Size row
            sizeLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: cardPad),
            sizeLabel.topAnchor.constraint(equalTo: colorWell.bottomAnchor, constant: 22),
            sizeSlider.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: cardPad),
            sizeSlider.trailingAnchor.constraint(equalTo: sizeValueLabel.leadingAnchor, constant: -8),
            sizeSlider.topAnchor.constraint(equalTo: sizeLabel.bottomAnchor, constant: 4),
            sizeSlider.heightAnchor.constraint(equalToConstant: rowH),
            sizeValueLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -cardPad),
            sizeValueLabel.centerYAnchor.constraint(equalTo: sizeSlider.centerYAnchor),
            sizeValueLabel.widthAnchor.constraint(equalToConstant: 48),

            // Ring width row
            lineWidthLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: cardPad),
            lineWidthLabel.topAnchor.constraint(equalTo: sizeSlider.bottomAnchor, constant: 18),
            lineWidthSlider.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: cardPad),
            lineWidthSlider.trailingAnchor.constraint(equalTo: lineWidthValueLabel.leadingAnchor, constant: -8),
            lineWidthSlider.topAnchor.constraint(equalTo: lineWidthLabel.bottomAnchor, constant: 4),
            lineWidthSlider.heightAnchor.constraint(equalToConstant: rowH),
            lineWidthValueLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -cardPad),
            lineWidthValueLabel.centerYAnchor.constraint(equalTo: lineWidthSlider.centerYAnchor),
            lineWidthValueLabel.widthAnchor.constraint(equalToConstant: 48),

            // Duration row
            durLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: cardPad),
            durLabel.topAnchor.constraint(equalTo: lineWidthSlider.bottomAnchor, constant: 18),
            durationSlider.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: cardPad),
            durationSlider.trailingAnchor.constraint(equalTo: durationValueLabel.leadingAnchor, constant: -8),
            durationSlider.topAnchor.constraint(equalTo: durLabel.bottomAnchor, constant: 4),
            durationSlider.heightAnchor.constraint(equalToConstant: rowH),
            durationValueLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -cardPad),
            durationValueLabel.centerYAnchor.constraint(equalTo: durationSlider.centerYAnchor),
            durationValueLabel.widthAnchor.constraint(equalToConstant: 48),

            // Ring count row
            ringLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: cardPad),
            ringLabel.topAnchor.constraint(equalTo: durationSlider.bottomAnchor, constant: 18),
            ringLabel.centerYAnchor.constraint(equalTo: ringCountStepper.centerYAnchor),
            ringCountLabel.trailingAnchor.constraint(equalTo: ringCountStepper.leadingAnchor, constant: -8),
            ringCountLabel.centerYAnchor.constraint(equalTo: ringCountStepper.centerYAnchor),
            ringCountLabel.widthAnchor.constraint(equalToConstant: 52),
            ringCountStepper.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -cardPad),
            ringCountStepper.topAnchor.constraint(equalTo: durationSlider.bottomAnchor, constant: 18),

            // Drag toggle row
            dragLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: cardPad),
            dragLabel.topAnchor.constraint(equalTo: ringCountStepper.bottomAnchor, constant: 20),
            dragLabel.centerYAnchor.constraint(equalTo: dragToggle.centerYAnchor),
            dragToggle.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -cardPad),
            dragToggle.topAnchor.constraint(equalTo: ringCountStepper.bottomAnchor, constant: 20),

            // Circle cursor toggle row
            cursorToggleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: cardPad),
            cursorToggleLabel.topAnchor.constraint(equalTo: dragToggle.bottomAnchor, constant: 20),
            cursorToggleLabel.centerYAnchor.constraint(equalTo: circleCursorToggle.centerYAnchor),
            circleCursorToggle.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -cardPad),
            circleCursorToggle.topAnchor.constraint(equalTo: dragToggle.bottomAnchor, constant: 20),

            // Cursor size row
            cursorSizeRow.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: cardPad),
            cursorSizeRow.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -cardPad),
            cursorSizeRow.topAnchor.constraint(equalTo: circleCursorToggle.bottomAnchor, constant: 14),
            cursorSizeRow.heightAnchor.constraint(equalToConstant: 52),
            cursorSizeRow.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -cardPad),

            // Quit
            quitBtn.topAnchor.constraint(equalTo: card.bottomAnchor, constant: 16),
            quitBtn.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            quitBtn.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
        ])
    }

    // MARK: - Helpers

    @discardableResult
    private func addSeparator(to view: NSView, below anchor: NSView, insets: CGFloat) -> NSView {
        let sep = NSView()
        sep.translatesAutoresizingMaskIntoConstraints = false
        sep.wantsLayer = true
        sep.layer?.backgroundColor = NSColor(calibratedWhite: 0.28, alpha: 1).cgColor
        view.addSubview(sep)
        NSLayoutConstraint.activate([
            sep.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets),
            sep.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -insets),
            sep.topAnchor.constraint(equalTo: anchor.bottomAnchor, constant: 12),
            sep.heightAnchor.constraint(equalToConstant: 0.5),
        ])
        return sep
    }

    private func makeLabel(_ text: String, size: CGFloat, bold: Bool, color: NSColor) -> NSTextField {
        let lbl = NSTextField(labelWithString: text)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.font = bold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size)
        lbl.textColor = color
        lbl.isBordered = false
        lbl.isEditable = false
        lbl.backgroundColor = .clear
        return lbl
    }

    // MARK: - Actions

    @objc private func powerToggled() {
        config.isEnabled = powerToggle.state == .on
        powerLabel.stringValue = config.isEnabled ? "ON" : "OFF"
        powerLabel.textColor = config.isEnabled ? .systemGreen : NSColor(calibratedWhite: 0.4, alpha: 1)
        onConfigChanged?()
    }

    @objc private func colorChanged() {
        config.rippleColor = colorWell.color
        previewView.config = config
        onConfigChanged?()
    }

    @objc private func sizeChanged() {
        config.maxRadius = CGFloat(sizeSlider.doubleValue)
        sizeValueLabel.stringValue = "\(Int(config.maxRadius))px"
        previewView.config = config
        onConfigChanged?()
    }

    @objc private func lineWidthChanged() {
        config.lineWidth = CGFloat(lineWidthSlider.doubleValue)
        lineWidthValueLabel.stringValue = String(format: "%.1fpx", config.lineWidth)
        previewView.config = config
        onConfigChanged?()
    }

    @objc private func durationChanged() {
        config.animationDuration = durationSlider.doubleValue
        durationValueLabel.stringValue = String(format: "%.1fs", config.animationDuration)
        previewView.config = config
        onConfigChanged?()
    }

    @objc private func ringCountChanged() {
        config.rippleCount = Int(ringCountStepper.intValue)
        ringCountLabel.stringValue = "\(config.rippleCount) ring\(config.rippleCount == 1 ? "" : "s")"
        previewView.config = config
        onConfigChanged?()
    }

    @objc private func dragToggled() {
        config.dragEffectEnabled = dragToggle.state == .on
        onConfigChanged?()
    }

    @objc private func circleCursorToggled() {
        config.useCircleCursor = circleCursorToggle.state == .on
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.2
            cursorSizeRow.animator().alphaValue = config.useCircleCursor ? 1.0 : 0.35
        }
        onConfigChanged?()
    }

    @objc private func cursorSizeChanged() {
        config.circleCursorSize = CGFloat(cursorSizeSlider.doubleValue)
        cursorSizeValueLabel.stringValue = "\(Int(config.circleCursorSize))px"
        onConfigChanged?()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}

// MARK: - Preview Ripple View

class PreviewRippleView: NSView {
    var config: RippleConfig! {
        didSet { needsDisplay = true }
    }
    private var innerRippleView: RippleView!

    override init(frame: NSRect) { super.init(frame: frame); setup() }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        innerRippleView = RippleView(frame: bounds)
        innerRippleView.autoresizingMask = [.width, .height]
        addSubview(innerRippleView)
    }

    override func mouseDown(with event: NSEvent) {
        guard let config = config else { return }
        innerRippleView.rippleColor = config.rippleColor
        innerRippleView.maxRadius = min(config.maxRadius, 55)
        innerRippleView.animationDuration = config.animationDuration
        innerRippleView.rippleCount = config.rippleCount
        innerRippleView.lineWidth = config.lineWidth
        let pt = convert(event.locationInWindow, from: nil)
        innerRippleView.triggerRipple(at: pt, isDrag: false)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let ctx = NSGraphicsContext.current?.cgContext
        ctx?.setStrokeColor(NSColor(calibratedWhite: 0.3, alpha: 1).cgColor)
        ctx?.setLineWidth(0.5)
        ctx?.setLineDash(phase: 0, lengths: [4, 4])
        ctx?.move(to: CGPoint(x: center.x - 12, y: center.y))
        ctx?.addLine(to: CGPoint(x: center.x + 12, y: center.y))
        ctx?.move(to: CGPoint(x: center.x, y: center.y - 12))
        ctx?.addLine(to: CGPoint(x: center.x, y: center.y + 12))
        ctx?.strokePath()
        let hint = NSAttributedString(string: "click here", attributes: [
            .font: NSFont.systemFont(ofSize: 9),
            .foregroundColor: NSColor(calibratedWhite: 0.35, alpha: 1)
        ])
        let sz = hint.size()
        hint.draw(at: CGPoint(x: center.x - sz.width / 2, y: center.y + 14))
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }
}
