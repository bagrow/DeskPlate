import Cocoa

private let defaultIcon = "tag.fill"

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var spaceManager: SpaceManager!
    var statusItem: NSStatusItem!
    var statusMenu: NSMenu!
    var preferencesWindow: NSWindow?

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupMainMenu()
        spaceManager = SpaceManager()
        setupStatusBar()

        spaceManager.onMenubarLabelUpdate = { [weak self] label, iconName in
            guard let self = self, let button = self.statusItem.button else { return }
            button.title = " " + label
            if let iconName = iconName {
                button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: label)
            } else {
                button.image = NSImage(systemSymbolName: defaultIcon, accessibilityDescription: "Desk Plate")
            }
            button.imagePosition = .imageLeft
        }
        spaceManager.onMenubarLabelClear = { [weak self] in
            guard let self = self, let button = self.statusItem.button else { return }
            button.title = ""
            button.image = NSImage(systemSymbolName: defaultIcon, accessibilityDescription: "Desk Plate")
            button.imagePosition = .imageLeft
        }

        spaceManager.start()
    }

    private func setupMainMenu() {
        let mainMenu = NSMenu()
        let editItem = NSMenuItem()
        editItem.submenu = {
            let menu = NSMenu(title: "Edit")
            menu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
            menu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
            menu.addItem(.separator())
            menu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
            menu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
            menu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
            menu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
            return menu
        }()
        mainMenu.addItem(editItem)
        NSApp.mainMenu = mainMenu
    }

    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: defaultIcon, accessibilityDescription: "Desk Plate")
            button.imagePosition = .imageLeft
            button.target = self
            button.action = #selector(statusBarClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        statusMenu = NSMenu()
        statusMenu.addItem(NSMenuItem(title: "Edit Labels…", action: #selector(openPreferences), keyEquivalent: ","))
        statusMenu.addItem(NSMenuItem.separator())
        let posMenu = NSMenuItem(title: "Label Position", action: nil, keyEquivalent: "")
        let sub = NSMenu()
        for pos in LabelPosition.allCases {
            let item = NSMenuItem(title: pos.displayName, action: #selector(setPosition(_:)), keyEquivalent: "")
            item.representedObject = pos
            item.image = NSImage(systemSymbolName: pos.symbolName, accessibilityDescription: pos.displayName)
            item.state = pos == spaceManager.labelPosition ? .on : .off
            sub.addItem(item)
        }
        sub.delegate = self
        posMenu.submenu = sub
        statusMenu.addItem(posMenu)
        statusMenu.addItem(NSMenuItem.separator())
        statusMenu.addItem(NSMenuItem(title: "Quit Desk Plate", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    @objc func statusBarClicked() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            statusItem.menu = statusMenu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            openPreferences()
        }
    }

    @objc func openPreferences() {
        if preferencesWindow == nil {
            let vc = PreferencesViewController(spaceManager: spaceManager)
            let win = NSWindow(contentViewController: vc)
            win.title = "Desk Plate"
            win.styleMask = [.titled, .closable, .fullSizeContentView]
            win.titlebarAppearsTransparent = true
            win.titleVisibility = .hidden
            win.collectionBehavior = .moveToActiveSpace
            win.center()
            preferencesWindow = win
            NotificationCenter.default.addObserver(self, selector: #selector(prefsClosed), name: NSWindow.willCloseNotification, object: win)
        }
        NSApp.activate(ignoringOtherApps: true)
        preferencesWindow?.makeKeyAndOrderFront(nil)
    }

    @objc func prefsClosed(_ note: Notification) {
        NotificationCenter.default.removeObserver(self, name: NSWindow.willCloseNotification, object: note.object)
        preferencesWindow = nil
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        for item in menu.items {
            guard let pos = item.representedObject as? LabelPosition else { continue }
            item.state = pos == spaceManager.labelPosition ? .on : .off
        }
    }

    @objc func setPosition(_ sender: NSMenuItem) {
        guard let pos = sender.representedObject as? LabelPosition else { return }
        spaceManager.labelPosition = pos
    }
}
