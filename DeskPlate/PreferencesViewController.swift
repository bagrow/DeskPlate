import Cocoa
import ServiceManagement
import SwiftUI

private let rowPasteboardType = NSPasteboard.PasteboardType("com.bagrow.DeskPlate.row")

class PreferencesViewController: NSViewController {
    private let spaceManager: SpaceManager
    private var stackView: NSStackView!
    private var rows: [(Int, NSTextField)] = []
    private var iconButtons: [Int: NSButton] = [:]
    private var indexLabels: [Int: NSTextField] = [:]
    private var spaceChangeObserver: Any?
    private var iconPopover: NSPopover?
    private var rowViews: [DraggableRowView] = []
    private weak var highlightedRowView: DraggableRowView?
    private var offsetLabel: NSTextField!
    private var offsetField: NSTextField!
    private var offsetStepper: NSStepper!
    private var colorLabel: NSTextField!
    private var colorStack: NSStackView!
    private var colorButtons: [LabelTint: NSButton] = [:]
    private var overlayToggle: NSSwitch!
    private var hideUnlabeledToggle: NSSwitch!
    private var spaceCount: Int

    init(spaceManager: SpaceManager) {
        self.spaceManager = spaceManager
        // Use detected count, but show at least enough rows for any saved labels
        let detected = spaceManager.getSpaceCount()
        let highestSaved = max(
            spaceManager.labels.keys.max() ?? -1,
            spaceManager.icons.keys.max() ?? -1
        ) + 1
        self.spaceCount = max(detected, highestSaved)
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func loadView() {
        let contentView = PreferencesContentView(frame: NSRect(x: 0, y: 0, width: 400, height: 100))
        contentView.dropDelegate = self
        contentView.registerForDraggedTypes([rowPasteboardType])
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
        resizeToFit()

        spaceChangeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateHighlights()
        }

        spaceManager.onSpaceCountChanged = { [weak self] newCount in
            guard let self = self else { return }
            let highestSaved = max(
                self.spaceManager.labels.keys.max() ?? -1,
                self.spaceManager.icons.keys.max() ?? -1
            ) + 1
            let needed = max(newCount, highestSaved)
            guard needed != self.spaceCount else { return }
            self.spaceCount = needed
            self.rebuildRows()
        }
    }

    private func resizeToFit() {
        let fitting = view.fittingSize
        view.setFrameSize(NSSize(width: 400, height: fitting.height))
        view.window?.setContentSize(NSSize(width: 400, height: fitting.height))
    }

    private func updateHighlights() {
        for (index, label) in indexLabels {
            if spaceManager.activeSpaceIndices.contains(index) {
                label.textColor = .controlAccentColor
                label.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
            } else {
                label.textColor = .labelColor
                label.font = NSFont.systemFont(ofSize: 12)
            }
        }
    }

    deinit {
        if let observer = spaceChangeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    private func rebuildRows() {
        // Remove existing rows
        for row in rowViews {
            stackView.removeArrangedSubview(row)
            row.removeFromSuperview()
        }
        rows.removeAll()
        iconButtons.removeAll()
        indexLabels.removeAll()
        rowViews.removeAll()

        // Add new rows
        for i in 0..<spaceCount {
            let row = makeRow(index: i)
            stackView.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
        }

        resizeToFit()
    }

    func updateOverlayToggle(_ enabled: Bool) {
        overlayToggle?.state = enabled ? .on : .off
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        // Clear initial focus ring
        view.window?.makeFirstResponder(nil)
    }

    private func buildUI() {
        // Title
        let title = NSTextField(labelWithString: "Desk Plate")
        title.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        title.translatesAutoresizingMaskIntoConstraints = false
        title.setContentHuggingPriority(.required, for: .horizontal)
        title.toolTip = "The name\u{2019}s Plate. Desk Plate."
        view.addSubview(title)

        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let byline = NSTextField(labelWithString: "v\(version) by James Bagrow")
        byline.font = NSFont.systemFont(ofSize: 12)
        byline.textColor = .secondaryLabelColor
        byline.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(byline)

        let subtitle = NSTextField(labelWithString: "Assign a name and icon to each desktop space. Leave blank to show the default number. \u{2318}+drag to swap labels.")
        subtitle.font = NSFont.systemFont(ofSize: 11)
        subtitle.textColor = .secondaryLabelColor
        subtitle.lineBreakMode = .byWordWrapping
        subtitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subtitle)

        stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        for i in 0..<spaceCount {
            let row = makeRow(index: i)
            stackView.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
        }

        // Label position
        let posLabel = NSTextField(labelWithString: "Label Position")
        posLabel.font = NSFont.systemFont(ofSize: 12)
        posLabel.alignment = .right
        posLabel.toolTip = "Where to show the desktop label on screen"
        posLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(posLabel)

        let posPopup = NSPopUpButton(frame: .zero, pullsDown: false)
        posPopup.translatesAutoresizingMaskIntoConstraints = false
        for pos in LabelPosition.allCases {
            posPopup.addItem(withTitle: pos.displayName)
            posPopup.lastItem?.representedObject = pos
            posPopup.lastItem?.image = NSImage(systemSymbolName: pos.symbolName, accessibilityDescription: pos.displayName)
        }
        posPopup.selectItem(at: LabelPosition.allCases.firstIndex(of: spaceManager.labelPosition) ?? 0)
        posPopup.toolTip = "Where to show the desktop label on screen"
        posPopup.target = self
        posPopup.action = #selector(positionChanged(_:))
        view.addSubview(posPopup)

        offsetLabel = NSTextField(labelWithString: "Offset")
        offsetLabel.font = NSFont.systemFont(ofSize: 12)
        offsetLabel.toolTip = "Offset in pixels from the corner of the screen"
        offsetLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(offsetLabel)

        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimum = 0
        formatter.maximum = 200
        formatter.allowsFloats = false

        offsetField = NSTextField()
        offsetField.placeholderString = "0"
        offsetField.formatter = formatter
        offsetField.integerValue = Int(spaceManager.labelMargin)
        offsetField.font = NSFont.systemFont(ofSize: 12)
        offsetField.bezelStyle = .roundedBezel
        offsetField.alignment = .center
        offsetField.translatesAutoresizingMaskIntoConstraints = false
        offsetField.toolTip = "Offset in pixels from the corner of the screen"
        offsetField.delegate = self
        view.addSubview(offsetField)

        offsetStepper = NSStepper()
        let stepper = offsetStepper!
        stepper.minValue = 0
        stepper.maxValue = 200
        stepper.increment = 1
        stepper.integerValue = Int(spaceManager.labelMargin)
        stepper.valueWraps = false
        stepper.controlSize = .small
        stepper.translatesAutoresizingMaskIntoConstraints = false
        stepper.toolTip = "Offset in pixels from the corner of the screen"
        stepper.target = self
        stepper.action = #selector(stepperChanged(_:))
        view.addSubview(stepper)

        let hideOverlay = spaceManager.labelPosition == .inMenubar
        offsetLabel.isHidden = hideOverlay
        offsetField.isHidden = hideOverlay
        offsetStepper.isHidden = hideOverlay

        // Label Tint
        colorLabel = NSTextField(labelWithString: "Label Tint")
        colorLabel.font = NSFont.systemFont(ofSize: 12)
        colorLabel.alignment = .right
        colorLabel.toolTip = "Tint color for the desktop label overlay"
        colorLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(colorLabel)

        colorStack = NSStackView()
        colorStack.orientation = .horizontal
        colorStack.spacing = 6
        colorStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(colorStack)

        for tint in LabelTint.allCases {
            let btn = NSButton(frame: NSRect(x: 0, y: 0, width: 20, height: 20))
            btn.title = ""
            btn.bezelStyle = .recessed
            btn.isBordered = false
            btn.wantsLayer = true
            btn.layer?.cornerRadius = 10
            btn.layer?.masksToBounds = true
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.toolTip = tint == .clear ? "Clear (default)" : tint.displayName
            btn.target = self
            btn.action = #selector(colorButtonClicked(_:))

            if tint == .clear {
                // Draw a "no color" circle: light gray with a diagonal line
                btn.layer?.backgroundColor = NSColor.quaternaryLabelColor.cgColor
                btn.layer?.borderWidth = 1
                btn.layer?.borderColor = NSColor.tertiaryLabelColor.cgColor
            } else {
                btn.layer?.backgroundColor = tint.nsColor.cgColor
            }

            // Selection indicator
            if tint == spaceManager.labelTint {
                btn.layer?.borderWidth = 2
                btn.layer?.borderColor = NSColor.controlAccentColor.cgColor
            }

            NSLayoutConstraint.activate([
                btn.widthAnchor.constraint(equalToConstant: 20),
                btn.heightAnchor.constraint(equalToConstant: 20),
            ])

            colorButtons[tint] = btn
            colorStack.addArrangedSubview(btn)
        }

        colorLabel.isHidden = hideOverlay
        colorStack.isHidden = hideOverlay

        // Divider
        let divider = NSBox()
        divider.boxType = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(divider)

        // Toggle rows
        let overlayLabel = NSTextField(labelWithString: "Show Overlay")
        overlayLabel.font = NSFont.systemFont(ofSize: 12)
        overlayLabel.alignment = .right
        overlayLabel.toolTip = "Show or hide the desktop label overlay"
        overlayLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayLabel)

        overlayToggle = NSSwitch()
        overlayToggle.controlSize = .mini
        overlayToggle.translatesAutoresizingMaskIntoConstraints = false
        overlayToggle.state = spaceManager.overlayEnabled ? .on : .off
        overlayToggle.toolTip = "Show or hide the desktop label overlay"
        overlayToggle.target = self
        overlayToggle.action = #selector(overlayToggled(_:))
        view.addSubview(overlayToggle)

        let hideUnlabeledLabel = NSTextField(labelWithString: "Labeled Only")
        hideUnlabeledLabel.font = NSFont.systemFont(ofSize: 12)
        hideUnlabeledLabel.alignment = .right
        hideUnlabeledLabel.toolTip = "Only show the overlay on desktops with a custom label or icon"
        hideUnlabeledLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hideUnlabeledLabel)

        hideUnlabeledToggle = NSSwitch()
        hideUnlabeledToggle.controlSize = .mini
        hideUnlabeledToggle.translatesAutoresizingMaskIntoConstraints = false
        hideUnlabeledToggle.state = spaceManager.hideUnlabeled ? .on : .off
        hideUnlabeledToggle.toolTip = "Only show the overlay on desktops with a custom label or icon"
        hideUnlabeledToggle.target = self
        hideUnlabeledToggle.action = #selector(hideUnlabeledToggled(_:))
        view.addSubview(hideUnlabeledToggle)

        let loginLabel = NSTextField(labelWithString: "Start at Login")
        loginLabel.font = NSFont.systemFont(ofSize: 12)
        loginLabel.alignment = .right
        loginLabel.toolTip = "Automatically launch Desk Plate when you log in"
        loginLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loginLabel)

        let loginToggle = NSSwitch()
        loginToggle.controlSize = .mini
        loginToggle.translatesAutoresizingMaskIntoConstraints = false
        loginToggle.state = SMAppService.mainApp.status == .enabled ? .on : .off
        loginToggle.toolTip = "Automatically launch Desk Plate when you log in"
        loginToggle.target = self
        loginToggle.action = #selector(loginToggled(_:))
        view.addSubview(loginToggle)

        // Done button
        let doneBtn = NSButton(title: "Done", target: self, action: #selector(dismissWindow))
        doneBtn.keyEquivalent = "\r"
        doneBtn.bezelStyle = NSButton.BezelStyle.rounded
        doneBtn.toolTip = "Close this window (Return)"
        doneBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(doneBtn)

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
            title.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 78),

            byline.lastBaselineAnchor.constraint(equalTo: title.lastBaselineAnchor),
            byline.leadingAnchor.constraint(equalTo: title.trailingAnchor, constant: 8),

            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8),
            subtitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subtitle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            stackView.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            posLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 8),
            posLabel.trailingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: 80),
            posLabel.centerYAnchor.constraint(equalTo: posPopup.centerYAnchor),

            posPopup.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: 88),
            posPopup.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 16),

            offsetLabel.leadingAnchor.constraint(equalTo: posPopup.trailingAnchor, constant: 12),
            offsetLabel.centerYAnchor.constraint(equalTo: posPopup.centerYAnchor),

            offsetField.leadingAnchor.constraint(equalTo: offsetLabel.trailingAnchor, constant: 8),
            offsetField.widthAnchor.constraint(greaterThanOrEqualToConstant: 40),
            offsetField.centerYAnchor.constraint(equalTo: posPopup.centerYAnchor),

            stepper.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stepper.centerYAnchor.constraint(equalTo: posPopup.centerYAnchor),

            offsetField.trailingAnchor.constraint(equalTo: stepper.leadingAnchor, constant: -2),

            colorLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 8),
            colorLabel.trailingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: 80),
            colorLabel.topAnchor.constraint(equalTo: posPopup.bottomAnchor, constant: 12),

            colorStack.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: 88),
            colorStack.centerYAnchor.constraint(equalTo: colorLabel.centerYAnchor),

            divider.topAnchor.constraint(equalTo: colorLabel.bottomAnchor, constant: 12),
            divider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            divider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Row 1, Column 1: Show Overlay
            overlayLabel.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 12),
            overlayLabel.trailingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: 80),

            overlayToggle.centerYAnchor.constraint(equalTo: overlayLabel.centerYAnchor),
            overlayToggle.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: 88),

            // Row 1, Column 2: Start at Login
            loginLabel.centerYAnchor.constraint(equalTo: overlayLabel.centerYAnchor),
            loginLabel.leadingAnchor.constraint(equalTo: overlayToggle.trailingAnchor, constant: 16),

            loginToggle.centerYAnchor.constraint(equalTo: overlayLabel.centerYAnchor),
            loginToggle.leadingAnchor.constraint(equalTo: loginLabel.trailingAnchor, constant: 8),

            // Row 2, Column 1: Labeled Only
            hideUnlabeledLabel.topAnchor.constraint(equalTo: overlayLabel.bottomAnchor, constant: 8),
            hideUnlabeledLabel.trailingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: 80),

            hideUnlabeledToggle.centerYAnchor.constraint(equalTo: hideUnlabeledLabel.centerYAnchor),
            hideUnlabeledToggle.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: 88),

            doneBtn.topAnchor.constraint(equalTo: hideUnlabeledLabel.bottomAnchor, constant: 8),
            doneBtn.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            doneBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            doneBtn.widthAnchor.constraint(equalToConstant: 80),
        ])
    }

    private func makeRow(index: Int) -> NSView {
        let row = DraggableRowView()
        row.desktopIndex = index
        row.translatesAutoresizingMaskIntoConstraints = false

        let indexLabel = NSTextField(labelWithString: String(format: "Desktop %d", index + 1))
        indexLabel.font = NSFont.systemFont(ofSize: 12)
        indexLabel.alignment = .right
        indexLabel.translatesAutoresizingMaskIntoConstraints = false
        indexLabel.setContentHuggingPriority(.required, for: .horizontal)

        // Icon picker button
        let iconBtn = NSButton(frame: NSRect(x: 0, y: 0, width: 28, height: 28))
        iconBtn.bezelStyle = .recessed
        iconBtn.isBordered = true
        iconBtn.tag = index
        iconBtn.target = self
        iconBtn.action = #selector(iconButtonClicked(_:))
        iconBtn.translatesAutoresizingMaskIntoConstraints = false
        iconBtn.toolTip = "Custom icon for Desktop \(index + 1)"
        iconBtn.imagePosition = .imageOnly
        applyIcon(spaceManager.icons[index], to: iconBtn)
        iconButtons[index] = iconBtn

        let field = NSTextField()
        field.placeholderString = "Desktop \(index + 1)"
        field.stringValue = spaceManager.labels[index] ?? ""
        field.font = NSFont.systemFont(ofSize: 13)
        field.bezelStyle = .roundedBezel
        field.translatesAutoresizingMaskIntoConstraints = false
        field.tag = index
        field.delegate = self
        field.toolTip = "Custom name for Desktop \(index + 1)"
        field.target = self
        field.action = #selector(fieldChanged(_:))

        // Highlight active/visible spaces
        if spaceManager.activeSpaceIndices.contains(index) {
            indexLabel.toolTip = "Choose an icon and label for the current desktop"
            indexLabel.textColor = .controlAccentColor
            indexLabel.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        } else {
            indexLabel.toolTip = "Choose an icon and label for Desktop \(index + 1)"
        }

        indexLabels[index] = indexLabel
        row.addSubview(indexLabel)
        row.addSubview(iconBtn)
        row.addSubview(field)

        NSLayoutConstraint.activate([
            indexLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            indexLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            indexLabel.widthAnchor.constraint(equalToConstant: 80),

            iconBtn.leadingAnchor.constraint(equalTo: indexLabel.trailingAnchor, constant: 8),
            iconBtn.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            iconBtn.widthAnchor.constraint(equalToConstant: 36),
            iconBtn.heightAnchor.constraint(equalToConstant: 28),

            field.leadingAnchor.constraint(equalTo: iconBtn.trailingAnchor, constant: 4),
            field.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            field.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            row.heightAnchor.constraint(equalToConstant: 30),
        ])

        rows.append((index, field))
        rowViews.append(row)
        return row
    }

    @objc private func fieldChanged(_ sender: NSTextField) {
        let index = sender.tag
        let value = sender.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty {
            spaceManager.labels.removeValue(forKey: index)
        } else {
            spaceManager.labels[index] = value
        }
    }

    @objc private func iconButtonClicked(_ sender: NSButton) {
        let index = sender.tag
        let currentIcon = spaceManager.icons[index]

        let picker = IconPickerView(
            selectedIcon: currentIcon,
            onSelect: { [weak self] iconName in
                guard let self = self else { return }
                if let iconName = iconName {
                    self.spaceManager.icons[index] = iconName
                } else {
                    self.spaceManager.icons.removeValue(forKey: index)
                }
                self.applyIcon(iconName, to: sender)
                self.iconPopover?.close()
            }
        )

        let hostingController = NSHostingController(rootView: picker)
        hostingController.preferredContentSize = NSSize(width: 370, height: 385)

        let popover = NSPopover()
        popover.contentViewController = hostingController
        popover.behavior = .transient
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .maxY)
        iconPopover = popover
    }

    @objc private func positionChanged(_ sender: NSPopUpButton) {
        guard let pos = sender.selectedItem?.representedObject as? LabelPosition else { return }
        spaceManager.labelPosition = pos
        let hide = pos == .inMenubar
        offsetLabel.isHidden = hide
        offsetField.isHidden = hide
        offsetStepper.isHidden = hide
        colorLabel.isHidden = hide
        colorStack.isHidden = hide
    }

    @objc private func colorButtonClicked(_ sender: NSButton) {
        guard let tint = colorButtons.first(where: { $0.value === sender })?.key else { return }
        spaceManager.labelTint = tint

        // Update selection indicators
        for (t, btn) in colorButtons {
            if t == tint {
                btn.layer?.borderWidth = 2
                btn.layer?.borderColor = NSColor.controlAccentColor.cgColor
            } else if t == .clear {
                btn.layer?.borderWidth = 1
                btn.layer?.borderColor = NSColor.tertiaryLabelColor.cgColor
            } else {
                btn.layer?.borderWidth = 0
                btn.layer?.borderColor = nil
            }
        }
    }

    @objc private func stepperChanged(_ sender: NSStepper) {
        let value = sender.integerValue
        offsetField.integerValue = value
        spaceManager.labelMargin = CGFloat(value)
    }

    @objc private func overlayToggled(_ sender: NSSwitch) {
        spaceManager.overlayEnabled = sender.state == .on
    }

    @objc private func hideUnlabeledToggled(_ sender: NSSwitch) {
        spaceManager.hideUnlabeled = sender.state == .on
    }

    @objc private func loginToggled(_ sender: NSSwitch) {
        do {
            if sender.state == .on {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            sender.state = sender.state == .on ? .off : .on
        }
    }

    @objc private func dismissWindow() {
        // Save any pending text field changes
        view.window?.makeFirstResponder(nil)
        view.window?.close()
    }

    // MARK: - Drag and Drop

    private func rowView(at windowPoint: NSPoint) -> DraggableRowView? {
        let pointInView = view.convert(windowPoint, from: nil)
        for rowView in rowViews {
            let pointInRow = rowView.convert(pointInView, from: view)
            if rowView.bounds.contains(pointInRow) {
                return rowView
            }
        }
        return nil
    }

    func handleDraggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if let target = rowView(at: sender.draggingLocation) {
            highlightRow(target)
        }
        return .move
    }

    func handleDraggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        let target = rowView(at: sender.draggingLocation)
        if target !== highlightedRowView {
            clearHighlight()
            if let target = target {
                highlightRow(target)
            }
        }
        return target != nil ? .move : []
    }

    func handleDraggingExited(_ sender: NSDraggingInfo?) {
        clearHighlight()
    }

    func handlePerformDragOperation(_ sender: NSDraggingInfo) -> Bool {
        clearHighlight()

        guard let item = sender.draggingPasteboard.pasteboardItems?.first,
              let sourceStr = item.string(forType: rowPasteboardType),
              let sourceIdx = Int(sourceStr) else {
            return false
        }

        guard let targetRow = rowView(at: sender.draggingLocation) else { return false }
        let destIdx = targetRow.desktopIndex
        if sourceIdx == destIdx { return false }

        spaceManager.swapSpaces(sourceIdx, destIdx)

        // Update UI for both rows
        updateRowUI(at: sourceIdx)
        updateRowUI(at: destIdx)

        return true
    }

    private func updateRowUI(at index: Int) {
        if let (_, field) = rows.first(where: { $0.0 == index }) {
            field.stringValue = spaceManager.labels[index] ?? ""
        }
        if let btn = iconButtons[index] {
            applyIcon(spaceManager.icons[index], to: btn)
        }
    }

    private func applyIcon(_ iconName: String?, to button: NSButton) {
        button.image = NSImage(systemSymbolName: iconName ?? "square.dashed", accessibilityDescription: "Icon")
        button.contentTintColor = iconName != nil ? .controlAccentColor : .tertiaryLabelColor
    }

    private func highlightRow(_ row: DraggableRowView) {
        row.wantsLayer = true
        row.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.15).cgColor
        row.layer?.cornerRadius = 4
        highlightedRowView = row
    }

    private func clearHighlight() {
        highlightedRowView?.layer?.backgroundColor = nil
        highlightedRowView = nil
    }
}

fileprivate class PreferencesContentView: NSView {
    weak var dropDelegate: PreferencesViewController?

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(nil)
        super.mouseDown(with: event)
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return dropDelegate?.handleDraggingEntered(sender) ?? []
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return dropDelegate?.handleDraggingUpdated(sender) ?? []
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        dropDelegate?.handleDraggingExited(sender)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return dropDelegate?.handlePerformDragOperation(sender) ?? false
    }
}

fileprivate class DraggableRowView: NSView, NSDraggingSource {
    var desktopIndex: Int = 0

    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return .move
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        // When cmd is held, claim the entire row for drag initiation
        // point is in superview coordinates, so test against frame
        if NSEvent.modifierFlags.contains(.command) {
            return frame.contains(point) ? self : nil
        }
        return super.hitTest(point)
    }

    override func mouseDown(with event: NSEvent) {
        guard event.modifierFlags.contains(.command) else {
            super.mouseDown(with: event)
            return
        }

        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(String(desktopIndex), forType: rowPasteboardType)

        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)

        // Create a snapshot of the row as the drag image
        let dragImage: NSImage
        if let rep = bitmapImageRepForCachingDisplay(in: bounds) {
            cacheDisplay(in: bounds, to: rep)
            dragImage = NSImage(size: bounds.size)
            dragImage.addRepresentation(rep)
        } else {
            dragImage = NSImage(size: bounds.size)
        }
        draggingItem.setDraggingFrame(bounds, contents: dragImage)

        beginDraggingSession(with: [draggingItem], event: event, source: self)
    }
}

extension PreferencesViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        guard let field = obj.object as? NSTextField else { return }
        // Only the offset field needs live updates (moves the window as you type).
        // Label fields save on Return (via action) or focus loss (below).
        if field === offsetField {
            spaceManager.labelMargin = CGFloat(field.integerValue)
            offsetStepper.integerValue = field.integerValue
        }
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        guard let field = obj.object as? NSTextField, field !== offsetField else { return }
        fieldChanged(field)
    }
}
