import Cocoa
import SwiftUI

// MARK: - SwiftUI label view with glass button

struct GlassLabelView: View {
    let text: String
    let iconName: String?
    var tintColor: Color?

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: 6) {
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 13, weight: .medium))
                }
                Text(text)
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background {
                if let tintColor {
                    Capsule().fill(tintColor.opacity(0.3))
                }
            }
            .glassEffect(.clear, in: .capsule)
        }
    }
}

// MARK: - Window

class LabelWindow: NSPanel {
    private var currentPosition: LabelPosition
    private var hostingView: NSHostingView<GlassLabelView>!
    var margin: CGFloat = 0
    var tintColor: Color?
    private var refreshTimer: Timer?
    private var isMouseOver = false
    private var mouseMonitorGlobal: Any?
    private var mouseMonitorLocal: Any?
    private static let hoveredAlpha: CGFloat = 0.15

    init(position: LabelPosition) {
        self.currentPosition = position

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 44),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        setupWindow()
        setupViews()
        updatePosition(position)
    }

    private func setupWindow() {
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        ignoresMouseEvents = true
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        isFloatingPanel = true
    }

    private func startRefresh() {
        var toggle = false
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 3.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            toggle.toggle()
            let base = self.isMouseOver ? LabelWindow.hoveredAlpha : 1.0
            self.alphaValue = toggle ? (base - 0.002) : base
        }
    }

    // MARK: - Hover fade

    private func startMouseTracking() {
        mouseMonitorGlobal = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
            self?.checkMousePosition()
        }
        mouseMonitorLocal = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.checkMousePosition()
            return event
        }
    }

    private func stopMouseTracking() {
        if let monitor = mouseMonitorGlobal {
            NSEvent.removeMonitor(monitor)
            mouseMonitorGlobal = nil
        }
        if let monitor = mouseMonitorLocal {
            NSEvent.removeMonitor(monitor)
            mouseMonitorLocal = nil
        }
    }

    private func checkMousePosition() {
        let mouseLocation = NSEvent.mouseLocation
        let isInside = frame.contains(mouseLocation)
        guard isInside != isMouseOver else { return }
        isMouseOver = isInside

        // Pause refresh timer so it doesn't fight the animation
        refreshTimer?.invalidate()
        refreshTimer = nil

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            self.animator().alphaValue = isInside ? LabelWindow.hoveredAlpha : 1.0
        }, completionHandler: { [weak self] in
            self?.startRefresh()
        })
    }

    private func setupViews() {
        let hosting = NSHostingView(rootView: GlassLabelView(text: "", iconName: nil))
        hosting.frame = NSRect(x: 0, y: 0, width: 200, height: 44)
        contentView = hosting
        hostingView = hosting
    }

    func show(label: String, icon: String? = nil) {
        hostingView.rootView = GlassLabelView(text: label, iconName: icon, tintColor: tintColor)
        sizeToFit()
        orderFront(nil)
        if refreshTimer == nil { startRefresh() }
        if mouseMonitorGlobal == nil { startMouseTracking() }
    }

    override func orderOut(_ sender: Any?) {
        refreshTimer?.invalidate()
        refreshTimer = nil
        stopMouseTracking()
        isMouseOver = false
        super.orderOut(sender)
    }

    private func sizeToFit() {
        let size = hostingView.fittingSize
        setContentSize(size)
        hostingView.frame = NSRect(origin: .zero, size: size)
        updatePosition(currentPosition)
    }

    func updatePosition(_ position: LabelPosition) {
        currentPosition = position
        guard let screen = NSScreen.main else { return }
        let visibleFrame = screen.visibleFrame
        let winFrame = frame
        var origin = NSPoint.zero

        switch position {
        case .topLeft:
            origin = NSPoint(x: visibleFrame.minX + margin, y: visibleFrame.maxY - winFrame.height - margin)
        case .topRight:
            origin = NSPoint(x: visibleFrame.maxX - winFrame.width - margin, y: visibleFrame.maxY - winFrame.height - margin)
        case .bottomLeft:
            origin = NSPoint(x: visibleFrame.minX + margin, y: visibleFrame.minY + margin)
        case .bottomRight:
            origin = NSPoint(x: visibleFrame.maxX - winFrame.width - margin, y: visibleFrame.minY + margin)
        case .inMenubar:
            return
        }

        setFrameOrigin(origin)
    }
}
