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
    private var overlayWindows: [String: LabelWindow] = [:]  // keyed by CGS display identifier
    private var currentSpaceIndex: Int = 0
    private(set) var activeSpaceIndices: Set<Int> = []
    private var suppressDidSet = true
    var labels: [Int: String] = [:] {
        didSet { guard !suppressDidSet else { return }; saveLabels(); updateOverlay() }
    }
    var icons: [Int: String] = [:] {
        didSet { guard !suppressDidSet else { return }; saveIcons(); updateOverlay() }
    }
    var onMenubarLabelUpdate: ((String, String?) -> Void)?
    var onMenubarLabelClear: (() -> Void)?
    var onOverlayEnabledChanged: ((Bool) -> Void)?
    var onSpaceCountChanged: ((Int) -> Void)?
    private(set) var spaceCount: Int = 0

    var overlayEnabled: Bool = true {
        didSet {
            guard !suppressDidSet else { return }
            UserDefaults.standard.set(overlayEnabled, forKey: "overlayEnabled")
            onOverlayEnabledChanged?(overlayEnabled)
            updateOverlay()
        }
    }

    var hideUnlabeled: Bool = false {
        didSet {
            guard !suppressDidSet else { return }
            UserDefaults.standard.set(hideUnlabeled, forKey: "hideUnlabeled")
            updateOverlay()
        }
    }

    var labelPosition: LabelPosition = .topRight {
        didSet {
            UserDefaults.standard.set(labelPosition.rawValue, forKey: "labelPosition")
            if labelPosition == .inMenubar {
                for win in overlayWindows.values { win.orderOut(nil) }
                updateOverlay()
            } else {
                onMenubarLabelClear?()
                for win in overlayWindows.values { win.updatePosition(labelPosition) }
                updateOverlay()
            }
        }
    }

    var labelTint: LabelTint = .clear {
        didSet {
            UserDefaults.standard.set(labelTint.rawValue, forKey: "labelTint")
            for win in overlayWindows.values { win.tintColor = labelTint.swiftUIColor }
            updateOverlay()
        }
    }

    var labelMargin: CGFloat = 0 {
        didSet {
            UserDefaults.standard.set(Double(labelMargin), forKey: "labelMargin")
            for win in overlayWindows.values {
                win.margin = labelMargin
                win.updatePosition(labelPosition)
            }
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
        if UserDefaults.standard.object(forKey: "overlayEnabled") != nil {
            overlayEnabled = UserDefaults.standard.bool(forKey: "overlayEnabled")
        }
        hideUnlabeled = UserDefaults.standard.bool(forKey: "hideUnlabeled")
        suppressDidSet = false
        spaceCount = getSpaceCount()
    }

    func swapSpaces(_ a: Int, _ b: Int) {
        suppressDidSet = true
        let tmpLabel = labels[a]; labels[a] = labels[b]; labels[b] = tmpLabel
        let tmpIcon = icons[a]; icons[a] = icons[b]; icons[b] = tmpIcon
        suppressDidSet = false
        saveLabels(); saveIcons(); updateOverlay()
    }

    func start() {
        // Listen for space changes
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(activeSpaceChanged),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )

        // Listen for display configuration changes (connect/disconnect monitor)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        // Initial detection
        updateOverlay()
    }

    @objc private func screensChanged() {
        // Remove windows for disconnected displays
        let validIDs = Set((getPerDisplaySpaceInfo() ?? []).map { $0.displayID })
        for id in overlayWindows.keys where !validIDs.contains(id) {
            overlayWindows[id]?.orderOut(nil)
            overlayWindows.removeValue(forKey: id)
        }
        updateOverlay()
    }

    private func overlayWindow(for displayID: String, screen: NSScreen) -> LabelWindow {
        if let existing = overlayWindows[displayID] {
            existing.targetScreen = screen
            return existing
        }
        let win = LabelWindow(position: labelPosition)
        win.margin = labelMargin
        win.tintColor = labelTint.swiftUIColor
        win.targetScreen = screen
        overlayWindows[displayID] = win
        return win
    }

    @objc private func activeSpaceChanged() {
        updateOverlay()
    }

    // MARK: - Space detection via CGS (private framework)

    typealias CGSConnectionID = UInt32
    typealias CGSSpaceID = UInt64

    struct DisplaySpaceInfo {
        let displayID: String
        let currentSpaceGlobalIndex: Int
        let screen: NSScreen?
    }

    /// Map a CGS "Display Identifier" (e.g. "Main" or a UUID) to an NSScreen.
    private func screenForDisplayID(_ identifier: String) -> NSScreen? {
        if identifier == "Main" {
            return NSScreen.screens.first
        }
        for screen in NSScreen.screens {
            guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else { continue }
            if let uuid = CGDisplayCreateUUIDFromDisplayID(screenNumber)?.takeUnretainedValue() {
                let uuidString = CFUUIDCreateString(nil, uuid) as String?
                if uuidString == identifier {
                    return screen
                }
            }
        }
        return nil
    }

    func getPerDisplaySpaceInfo() -> [DisplaySpaceInfo]? {
        typealias CGSDefaultConnectionFunc = @convention(c) () -> CGSConnectionID
        typealias CGSCopyManagedDisplaySpacesFunc = @convention(c) (CGSConnectionID) -> CFArray?

        guard let connSym = dlsym(RTLD_DEFAULT, "_CGSDefaultConnection"),
              let managedSym = dlsym(RTLD_DEFAULT, "CGSCopyManagedDisplaySpaces") else {
            return nil
        }

        let connFn = unsafeBitCast(connSym, to: CGSDefaultConnectionFunc.self)
        let managedFn = unsafeBitCast(managedSym, to: CGSCopyManagedDisplaySpacesFunc.self)

        let conn = connFn()
        guard let displays = managedFn(conn) as? [[String: Any]] else { return nil }

        var result: [DisplaySpaceInfo] = []
        var globalIndex = 0

        for display in displays {
            guard let displayID = display["Display Identifier"] as? String,
                  let spaces = display["Spaces"] as? [[String: Any]],
                  let currentSpace = display["Current Space"] as? [String: Any],
                  let currentID = currentSpace["id64"] as? CGSSpaceID else {
                continue
            }

            var currentGlobalIndex = globalIndex  // fallback to first space on this display
            for (i, space) in spaces.enumerated() {
                if let spaceID = space["id64"] as? CGSSpaceID, spaceID == currentID {
                    currentGlobalIndex = globalIndex + i
                    break
                }
            }

            result.append(DisplaySpaceInfo(
                displayID: displayID,
                currentSpaceGlobalIndex: currentGlobalIndex,
                screen: screenForDisplayID(displayID)
            ))
            globalIndex += spaces.count
        }

        return result
    }

    func getSpaceCount() -> Int {
        typealias CGSDefaultConnectionFunc = @convention(c) () -> CGSConnectionID
        typealias CGSCopyManagedDisplaySpacesFunc = @convention(c) (CGSConnectionID) -> CFArray?

        guard let connSym = dlsym(RTLD_DEFAULT, "_CGSDefaultConnection"),
              let managedSym = dlsym(RTLD_DEFAULT, "CGSCopyManagedDisplaySpaces") else {
            return max(spaceCount, 1)
        }

        let connFn = unsafeBitCast(connSym, to: CGSDefaultConnectionFunc.self)
        let managedFn = unsafeBitCast(managedSym, to: CGSCopyManagedDisplaySpacesFunc.self)

        let conn = connFn()
        guard let rawDisplays = managedFn(conn) as? [[String: Any]] else {
            return max(spaceCount, 1)
        }

        var count = 0
        for display in rawDisplays {
            if let spaces = display["Spaces"] as? [[String: Any]] {
                count += spaces.count
            }
        }
        return max(count, 1)
    }

    // MARK: - Overlay Update

    func updateOverlay() {
        if !overlayEnabled {
            for win in overlayWindows.values { win.orderOut(nil) }
            onMenubarLabelClear?()
            return
        }

        let newCount = getSpaceCount()
        if newCount != spaceCount {
            spaceCount = newCount
            onSpaceCountChanged?(newCount)
        }

        guard let displayInfos = getPerDisplaySpaceInfo(), !displayInfos.isEmpty else {
            // CGS failed — show warning
            if labelPosition == .inMenubar {
                for win in overlayWindows.values { win.orderOut(nil) }
                onMenubarLabelUpdate?("Desktop ?", "exclamationmark.triangle")
            } else {
                onMenubarLabelClear?()
                // Show error on all existing windows
                for win in overlayWindows.values {
                    win.show(label: "Desktop ?", icon: "exclamationmark.triangle")
                }
            }
            return
        }

        // Track which display has the focused space (for menu bar label + currentSpaceIndex)
        let focusedDisplayID: String? = {
            typealias CGSDefaultConnectionFunc = @convention(c) () -> CGSConnectionID
            typealias CGSGetActiveSpaceFunc = @convention(c) (CGSConnectionID) -> CGSSpaceID
            guard let connSym = dlsym(RTLD_DEFAULT, "_CGSDefaultConnection"),
                  let activeSym = dlsym(RTLD_DEFAULT, "CGSGetActiveSpace") else { return nil }
            let connFn = unsafeBitCast(connSym, to: CGSDefaultConnectionFunc.self)
            let activeFn = unsafeBitCast(activeSym, to: CGSGetActiveSpaceFunc.self)
            let activeID = activeFn(connFn())
            // Find which display owns this space
            typealias CGSCopyManagedDisplaySpacesFunc = @convention(c) (CGSConnectionID) -> CFArray?
            guard let managedSym = dlsym(RTLD_DEFAULT, "CGSCopyManagedDisplaySpaces") else { return nil }
            let managedFn = unsafeBitCast(managedSym, to: CGSCopyManagedDisplaySpacesFunc.self)
            guard let displays = managedFn(connFn()) as? [[String: Any]] else { return nil }
            for display in displays {
                guard let displayID = display["Display Identifier"] as? String,
                      let spaces = display["Spaces"] as? [[String: Any]] else { continue }
                for space in spaces {
                    if let id = space["id64"] as? CGSSpaceID, id == activeID {
                        return displayID
                    }
                }
            }
            return nil
        }()

        // Collect all active space indices across displays
        activeSpaceIndices = Set(displayInfos.map { $0.currentSpaceGlobalIndex })

        // Update each display's overlay
        var menubarUpdated = false
        for info in displayInfos {
            let idx = info.currentSpaceGlobalIndex
            let label = labels[idx]
            let icon = icons[idx]
            let hasCustomLabel = (label != nil && !label!.isEmpty) || icon != nil
            let displayLabel = (label != nil && !label!.isEmpty) ? label! : "Desktop \(idx + 1)"

            // Update currentSpaceIndex for the focused display (used by preferences highlighting)
            if info.displayID == focusedDisplayID {
                currentSpaceIndex = idx
            }

            if labelPosition == .inMenubar {
                // Only show the focused display's label in the menu bar
                if info.displayID == focusedDisplayID {
                    if hideUnlabeled && !hasCustomLabel {
                        onMenubarLabelClear?()
                    } else {
                        onMenubarLabelUpdate?(displayLabel, icon)
                    }
                    menubarUpdated = true
                }
                overlayWindows[info.displayID]?.orderOut(nil)
            } else if hideUnlabeled && !hasCustomLabel {
                overlayWindows[info.displayID]?.orderOut(nil)
            } else if let screen = info.screen {
                let win = overlayWindow(for: info.displayID, screen: screen)
                win.show(label: displayLabel, icon: icon)
            }
        }

        if labelPosition == .inMenubar {
            if !menubarUpdated { onMenubarLabelClear?() }
        } else {
            onMenubarLabelClear?()
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
