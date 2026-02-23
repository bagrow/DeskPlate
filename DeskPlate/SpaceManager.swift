import Cocoa
import SwiftUI

// MARK: - Position enum

enum LabelPosition: String, CaseIterable, Codable {
    case topLeft, topRight, bottomLeft, bottomRight, inMenubar

    var displayName: String {
        switch self {
        case .topLeft: return "Top Left"
        case .topRight: return "Top Right"
        case .bottomLeft: return "Bottom Left"
        case .bottomRight: return "Bottom Right"
        case .inMenubar: return "In Menu Bar"
        }
    }

    var symbolName: String {
        switch self {
        case .topLeft: return "rectangle.inset.topleft.filled"
        case .topRight: return "rectangle.inset.topright.filled"
        case .bottomLeft: return "rectangle.inset.bottomleft.filled"
        case .bottomRight: return "rectangle.inset.bottomright.filled"
        case .inMenubar: return "menubar.rectangle"
        }
    }
}

// MARK: - Tint enum

enum LabelTint: String, CaseIterable, Codable {
    case clear, blue, purple, red, orange, yellow, green, gray

    var displayName: String {
        switch self {
        case .clear:  return "Clear"
        case .blue:   return "Blue"
        case .purple: return "Purple"
        case .red:    return "Red"
        case .orange: return "Orange"
        case .yellow: return "Yellow"
        case .green:  return "Green"
        case .gray:   return "Gray"
        }
    }

    var swiftUIColor: Color? {
        switch self {
        case .clear:  return nil
        case .blue:   return .blue
        case .purple: return .purple
        case .red:    return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green:  return .green
        case .gray:   return .gray
        }
    }

    var nsColor: NSColor {
        switch self {
        case .clear:  return .clear
        case .blue:   return .systemBlue
        case .purple: return .systemPurple
        case .red:    return .systemRed
        case .orange: return .systemOrange
        case .yellow: return .systemYellow
        case .green:  return .systemGreen
        case .gray:   return .systemGray
        }
    }
}

// Swift can't import RTLD_DEFAULT (C macro with pointer cast), so define it manually.
private let RTLD_DEFAULT = UnsafeMutableRawPointer(bitPattern: -2)

// MARK: - SpaceManager

class SpaceManager: NSObject {
    private var overlayWindow: LabelWindow?
    private var currentSpaceIndex: Int = 0
    private var suppressDidSet = true
    var labels: [Int: String] = [:] {
        didSet { guard !suppressDidSet else { return }; saveLabels(); updateOverlay() }
    }
    var icons: [Int: String] = [:] {
        didSet { guard !suppressDidSet else { return }; saveIcons(); updateOverlay() }
    }
    var onMenubarLabelUpdate: ((String, String?) -> Void)?
    var onMenubarLabelClear: (() -> Void)?

    var labelPosition: LabelPosition = .topRight {
        didSet {
            UserDefaults.standard.set(labelPosition.rawValue, forKey: "labelPosition")
            if labelPosition == .inMenubar {
                overlayWindow?.orderOut(nil)
                updateOverlay()
            } else {
                onMenubarLabelClear?()
                overlayWindow?.updatePosition(labelPosition)
                updateOverlay()
            }
        }
    }

    var labelTint: LabelTint = .clear {
        didSet {
            UserDefaults.standard.set(labelTint.rawValue, forKey: "labelTint")
            overlayWindow?.tintColor = labelTint.swiftUIColor
            updateOverlay()
        }
    }

    var labelMargin: CGFloat = 0 {
        didSet {
            UserDefaults.standard.set(Double(labelMargin), forKey: "labelMargin")
            overlayWindow?.margin = labelMargin
            overlayWindow?.updatePosition(labelPosition)
        }
    }

    private let defaultsKey = "spaceLabels"
    private let iconsDefaultsKey = "spaceIcons"

    override init() {
        super.init()
        loadLabels()
        loadIcons()
        if let posStr = UserDefaults.standard.string(forKey: "labelPosition"),
           let pos = LabelPosition(rawValue: posStr) {
            labelPosition = pos
        }
        labelMargin = CGFloat(UserDefaults.standard.double(forKey: "labelMargin"))
        if let tintStr = UserDefaults.standard.string(forKey: "labelTint"),
           let tint = LabelTint(rawValue: tintStr) {
            labelTint = tint
        }
        suppressDidSet = false
    }

    func swapSpaces(_ a: Int, _ b: Int) {
        suppressDidSet = true
        let tmpLabel = labels[a]; labels[a] = labels[b]; labels[b] = tmpLabel
        let tmpIcon = icons[a]; icons[a] = icons[b]; icons[b] = tmpIcon
        suppressDidSet = false
        saveLabels(); saveIcons(); updateOverlay()
    }

    func start() {
        // Create the overlay window
        overlayWindow = LabelWindow(position: labelPosition)
        overlayWindow?.margin = labelMargin
        overlayWindow?.tintColor = labelTint.swiftUIColor

        // Listen for space changes
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(activeSpaceChanged),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )

        // Initial detection
        updateOverlay()
    }

    @objc private func activeSpaceChanged() {
        updateOverlay()
    }

    // MARK: - Space Index via CGS (private framework)

    typealias CGSConnectionID = UInt32
    typealias CGSSpaceID = UInt64

    func getSpaceIndexUsingCGS() -> Int? {
        typealias CGSDefaultConnectionFunc = @convention(c) () -> CGSConnectionID
        typealias CGSCopyManagedDisplaySpacesFunc = @convention(c) (CGSConnectionID) -> CFArray?
        typealias CGSGetActiveSpaceFunc = @convention(c) (CGSConnectionID) -> CGSSpaceID

        guard let connSym = dlsym(RTLD_DEFAULT, "_CGSDefaultConnection"),
              let activeSpaceSym = dlsym(RTLD_DEFAULT, "CGSGetActiveSpace"),
              let managedSym = dlsym(RTLD_DEFAULT, "CGSCopyManagedDisplaySpaces") else {
            NSLog("DeskPlate: failed to load CGS symbols")
            return nil
        }

        let connFn = unsafeBitCast(connSym, to: CGSDefaultConnectionFunc.self)
        let activeSpaceFn = unsafeBitCast(activeSpaceSym, to: CGSGetActiveSpaceFunc.self)
        let managedFn = unsafeBitCast(managedSym, to: CGSCopyManagedDisplaySpacesFunc.self)

        let conn = connFn()
        let activeSpaceID = activeSpaceFn(conn)

        guard let displays = managedFn(conn) as? [[String: Any]] else {
            NSLog("DeskPlate: CGSCopyManagedDisplaySpaces returned nil")
            return nil
        }

        var allSpaces: [CGSSpaceID] = []
        for display in displays {
            if let spaces = display["Spaces"] as? [[String: Any]] {
                for space in spaces {
                    if let spaceID = space["id64"] as? CGSSpaceID {
                        allSpaces.append(spaceID)
                    }
                }
            }
        }

        if let idx = allSpaces.firstIndex(of: activeSpaceID) {
            return idx
        }
        NSLog("DeskPlate: active space ID %llu not found in space list", activeSpaceID)
        return nil
    }

    // MARK: - Overlay Update

    func updateOverlay() {
        guard let realIndex = getSpaceIndexUsingCGS() else {
            // CGS failed — show warning instead of wrong desktop
            if labelPosition == .inMenubar {
                overlayWindow?.orderOut(nil)
                onMenubarLabelUpdate?("Desktop ?", "exclamationmark.triangle")
            } else {
                onMenubarLabelClear?()
                overlayWindow?.show(label: "Desktop ?", icon: "exclamationmark.triangle")
            }
            return
        }
        currentSpaceIndex = realIndex

        let label = labels[currentSpaceIndex]
        let icon = icons[currentSpaceIndex]

        let displayLabel: String
        if let label = label, !label.isEmpty {
            displayLabel = label
        } else {
            displayLabel = "Desktop \(currentSpaceIndex + 1)"
        }

        if labelPosition == .inMenubar {
            overlayWindow?.orderOut(nil)
            onMenubarLabelUpdate?(displayLabel, icon)
        } else {
            onMenubarLabelClear?()
            overlayWindow?.show(label: displayLabel, icon: icon)
        }
    }

    var currentIndex: Int { currentSpaceIndex }

    // MARK: - Persistence

    private func saveLabels() {
        let encoded = labels.reduce(into: [String: String]()) { dict, pair in
            dict[String(pair.key)] = pair.value
        }
        UserDefaults.standard.set(encoded, forKey: defaultsKey)
    }

    private func loadLabels() {
        guard let saved = UserDefaults.standard.dictionary(forKey: defaultsKey) as? [String: String] else { return }
        labels = saved.reduce(into: [Int: String]()) { dict, pair in
            if let key = Int(pair.key) { dict[key] = pair.value }
        }
    }

    private func saveIcons() {
        let encoded = icons.reduce(into: [String: String]()) { dict, pair in
            dict[String(pair.key)] = pair.value
        }
        UserDefaults.standard.set(encoded, forKey: iconsDefaultsKey)
    }

    private func loadIcons() {
        guard let saved = UserDefaults.standard.dictionary(forKey: iconsDefaultsKey) as? [String: String] else { return }
        icons = saved.reduce(into: [Int: String]()) { dict, pair in
            if let key = Int(pair.key) { dict[key] = pair.value }
        }
    }
}
