import SwiftUI

// MARK: - Symbol Catalog

struct SFSymbolCategory {
    let name: String
    let symbols: [String]
}

enum SFSymbolCatalog {
    static let categories: [SFSymbolCategory] = [
        SFSymbolCategory(name: "Work", symbols: [
            "desktopcomputer", "laptopcomputer", "display",
            "doc.text", "folder", "tray.full",
            "briefcase", "building.2", "chart.bar",
            "calendar", "clock", "printer",
            "paperplane", "list.bullet", "checkmark.circle"
        ]),
        SFSymbolCategory(name: "Science", symbols: [
            "atom", "flask", "function",
            "waveform.path.ecg", "chart.xyaxis.line",
            "brain", "microbe", "testtube.2",
            "leaf", "drop", "bolt",
            "cpu", "globe", "chart.bar",
            "stethoscope", "waveform"
        ]),
        SFSymbolCategory(name: "Writing", symbols: [
            "pencil", "doc.text", "book",
            "doc.on.doc", "list.bullet.clipboard",
            "note.text", "highlighter", "quote.opening",
            "textformat", "text.cursor", "bookmark", "paperclip",
            "folder", "printer", "doc.richtext"
        ]),
        SFSymbolCategory(name: "Communication", symbols: [
            "envelope", "phone", "message",
            "bubble.left", "video", "person",
            "person.2", "at", "megaphone",
            "bubble.left.and.bubble.right", "phone.bubble",
            "shared.with.you"
        ]),
        SFSymbolCategory(name: "Tools", symbols: [
            "wrench", "gearshape", "hammer",
            "terminal", "chevron.left.forwardslash.chevron.right",
            "ant", "ladybug", "cpu",
            "externaldrive", "memorychip", "bolt.horizontal",
            "screwdriver"
        ]),
        SFSymbolCategory(name: "Objects", symbols: [
            "book", "pencil", "scissors",
            "paperclip", "lock", "key",
            "flag", "tag", "bell",
            "heart", "bolt", "cube",
            "gift", "cart", "creditcard",
            "cup.and.saucer", "alarm", "lightbulb",
            "exclamationmark.triangle", "info.circle",
            "sparkles", "sparkles.rectangle.stack"
        ]),
        SFSymbolCategory(name: "Media", symbols: [
            "play.circle", "music.note", "headphones",
            "film", "camera", "photo",
            "tv", "gamecontroller", "paintbrush",
            "guitars", "pianokeys", "radio",
            "speaker.wave.2"
        ]),
        SFSymbolCategory(name: "Web & Cloud", symbols: [
            "globe", "network", "wifi",
            "cloud", "link", "safari",
            "server.rack", "antenna.radiowaves.left.and.right",
            "icloud", "arrow.up.arrow.down.circle",
            "lock.shield"
        ]),
        SFSymbolCategory(name: "Finance", symbols: [
            "dollarsign.circle", "dollarsign.square",
            "banknote", "creditcard", "cart",
            "bag", "giftcard", "wallet.bifold",
            "chart.line.uptrend.xyaxis", "percent",
            "building.columns", "chart.pie"
        ]),
        SFSymbolCategory(name: "Teaching & Presenting", symbols: [
            "videoprojector", "studentdesk", "person.and.background.dotted",
            "graduationcap", "books.vertical", "person.3",
            "hand.raised", "questionmark.bubble", "mic",
            "pencil.and.ruler", "rectangle.inset.filled.and.person.filled",
            "lanyardcard", "laser.burst", "timer",
            "person.crop.rectangle"
        ]),
        SFSymbolCategory(name: "Nature & Places", symbols: [
            "leaf", "sun.max", "moon",
            "star", "house", "building",
            "mountain.2", "tree", "drop",
            "flame", "snowflake", "wind"
        ]),
    ]

    static let displayNames: [String: String] = [
        "desktopcomputer": "Desktop Computer",
        "laptopcomputer": "Laptop",
        "display": "Display",
        "doc.text": "Document",
        "folder": "Folder",
        "tray.full": "Inbox",
        "briefcase": "Briefcase",
        "building.2": "Buildings",
        "chart.bar": "Bar Chart",
        "calendar": "Calendar",
        "clock": "Clock",
        "printer": "Printer",
        "paperplane": "Paper Plane",
        "list.bullet": "List",
        "checkmark.circle": "Checkmark",
        "atom": "Atom",
        "flask": "Flask",
        "function": "Function",
        "waveform.path.ecg": "ECG",
        "chart.xyaxis.line": "Line Chart",
        "brain": "Brain",
        "microbe": "Microbe",
        "testtube.2": "Test Tubes",
        "stethoscope": "Stethoscope",
        "waveform": "Waveform",
        "doc.on.doc": "Documents",
        "text.cursor": "Text Cursor",
        "list.bullet.clipboard": "Clipboard",
        "note.text": "Note",
        "highlighter": "Highlighter",
        "quote.opening": "Quote",
        "textformat": "Text Format",
        "bookmark": "Bookmark",
        "doc.richtext": "Rich Text Document",
        "envelope": "Envelope",
        "phone": "Phone",
        "message": "Message",
        "bubble.left": "Chat Bubble",
        "video": "Video",
        "person": "Person",
        "person.2": "People",
        "at": "At Sign",
        "megaphone": "Megaphone",
        "bubble.left.and.bubble.right": "Conversation",
        "phone.bubble": "Phone Chat",
        "shared.with.you": "Shared",
        "play.circle": "Play",
        "music.note": "Music",
        "headphones": "Headphones",
        "film": "Film",
        "camera": "Camera",
        "photo": "Photo",
        "tv": "TV",
        "gamecontroller": "Game Controller",
        "paintbrush": "Paintbrush",
        "guitars": "Guitars",
        "pianokeys": "Piano Keys",
        "radio": "Radio",
        "speaker.wave.2": "Speaker",
        "wrench": "Wrench",
        "gearshape": "Gear",
        "hammer": "Hammer",
        "terminal": "Terminal",
        "chevron.left.forwardslash.chevron.right": "Code",
        "ant": "Ant",
        "ladybug": "Ladybug",
        "cpu": "CPU",
        "externaldrive": "External Drive",
        "memorychip": "Memory Chip",
        "bolt.horizontal": "Horizontal Bolt",
        "screwdriver": "Screwdriver",
        "globe": "Globe",
        "network": "Network",
        "wifi": "Wi-Fi",
        "cloud": "Cloud",
        "link": "Link",
        "safari": "Safari",
        "server.rack": "Server Rack",
        "antenna.radiowaves.left.and.right": "Antenna",
        "icloud": "iCloud",
        "arrow.up.arrow.down.circle": "Upload / Download",
        "lock.shield": "Security Shield",
        "leaf": "Leaf",
        "sun.max": "Sun",
        "moon": "Moon",
        "star": "Star",
        "house": "House",
        "building": "Building",
        "mountain.2": "Mountains",
        "tree": "Tree",
        "drop": "Water Drop",
        "flame": "Flame",
        "snowflake": "Snowflake",
        "wind": "Wind",
        "book": "Book",
        "pencil": "Pencil",
        "scissors": "Scissors",
        "paperclip": "Paper Clip",
        "lock": "Lock",
        "key": "Key",
        "flag": "Flag",
        "tag": "Tag",
        "bell": "Bell",
        "heart": "Heart",
        "bolt": "Bolt",
        "cube": "Cube",
        "gift": "Gift",
        "cart": "Cart",
        "creditcard": "Credit Card",
        "cup.and.saucer": "Cup & Saucer",
        "alarm": "Alarm Clock",
        "lightbulb": "Light Bulb",
        "exclamationmark.triangle": "Warning",
        "info.circle": "Info",
        "sparkles": "Sparkles",
        "sparkles.rectangle.stack": "Sparkles Stack",
        "dollarsign.circle": "Dollar",
        "dollarsign.square": "Dollar Square",
        "banknote": "Banknote",
        "bag": "Shopping Bag",
        "giftcard": "Gift Card",
        "wallet.bifold": "Wallet",
        "chart.line.uptrend.xyaxis": "Uptrend",
        "percent": "Percent",
        "building.columns": "Bank",
        "chart.pie": "Pie Chart",
        "videoprojector": "Video Projector",
        "studentdesk": "Student Desk",
        "person.and.background.dotted": "Person (Dotted)",
        "graduationcap": "Graduation Cap",
        "books.vertical": "Books",
        "person.3": "Class / Group",
        "hand.raised": "Raised Hand",
        "questionmark.bubble": "Question",
        "mic": "Microphone",
        "pencil.and.ruler": "Pencil & Ruler",
        "rectangle.inset.filled.and.person.filled": "Presenter Display",
        "lanyardcard": "Lanyard Badge",
        "laser.burst": "Laser Pointer",
        "timer": "Timer",
        "person.crop.rectangle": "Person Badge",
    ]

    static func displayName(for symbol: String) -> String {
        displayNames[symbol] ?? symbol
    }
}

// MARK: - Icon Picker View

struct IconPickerView: View {
    let selectedIcon: String?
    let onSelect: (String?) -> Void

    @State private var searchText = ""

    private let columns = Array(repeating: GridItem(.fixed(36), spacing: 8), count: 8)

    private var filteredCategories: [SFSymbolCategory] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if query.isEmpty { return SFSymbolCatalog.categories }
        return SFSymbolCatalog.categories.compactMap { category in
            if category.name.lowercased().contains(query) {
                return category
            }
            let matched = category.symbols.filter { symbol in
                symbol.lowercased().contains(query)
                    || SFSymbolCatalog.displayName(for: symbol).lowercased().contains(query)
            }
            return matched.isEmpty ? nil : SFSymbolCategory(name: category.name, symbols: matched)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
                TextField("Search symbols…", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    Button(action: { onSelect(nil) }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 12))
                            Text("No Icon")
                                .font(.system(size: 12))
                            Spacer()
                            if selectedIcon == nil {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12))
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    ForEach(Array(filteredCategories.enumerated()), id: \.offset) { _, category in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(category.name)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            LazyVGrid(columns: columns, spacing: 4) {
                                ForEach(category.symbols, id: \.self) { symbolName in
                                    Button(action: { onSelect(symbolName) }) {
                                        Image(systemName: symbolName)
                                            .font(.system(size: 16))
                                            .frame(width: 32, height: 32)
                                            .background(
                                                selectedIcon == symbolName
                                                    ? Color.accentColor.opacity(0.2)
                                                    : Color.clear
                                            )
                                            .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                    .help(SFSymbolCatalog.displayName(for: symbolName))
                                }
                            }
                        }
                    }
                }
                .padding(12)
            }
        }
    }
}
