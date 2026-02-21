import Cocoa
import SwiftUI

// MARK: - SwiftUI label view with glass button

struct GlassLabelView: View {
    let text: String
    let iconName: String?

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
            .glassEffect(.clear, in: .capsule)
        }
    }
}

// MARK: - Window

class LabelWindow: NSPanel {
    private var currentPosition: LabelPosition
    private var hostingView: NSHostingView<GlassLabelView>!
    var margin: CGFloat = 0
    private var refreshTimer: Timer?

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
            self.alphaValue = toggle ? 0.998 : 1.0
        }
    }

    private func setupViews() {
        let hosting = NSHostingView(rootView: GlassLabelView(text: "", iconName: nil))
        hosting.frame = NSRect(x: 0, y: 0, width: 200, height: 44)
        contentView = hosting
        hostingView = hosting
    }

    func show(label: String, icon: String? = nil) {
        hostingView.rootView = GlassLabelView(text: label, iconName: icon)
        sizeToFit()
        orderFront(nil)
        if refreshTimer == nil { startRefresh() }
    }

    override func orderOut(_ sender: Any?) {
        refreshTimer?.invalidate()
        refreshTimer = nil
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
