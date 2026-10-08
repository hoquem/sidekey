import Foundation

/// Layouts for widely used Mac apps. Each layout documents where its shortcuts come from: the app's
/// own menu bar where the app was available to read, otherwise the vendor's published shortcuts.
extension DefaultProfiles {
    /// Safari (``com.apple.Safari``). Shortcuts from Safari's menu bar.
    public static func makeSafariProfile() -> DeckProfile {
        DeckProfile(
            id: "com.apple.Safari",
            appBundleIdentifier: "com.apple.Safari",
            appName: "Safari",
            rows: 3,
            columns: 5,
            keys: [
                DeckKey(
                    position: 0,
                    label: "New Tab",
                    iconSystemName: "plus.square",
                    action: .hotkey(key: "t", modifiers: [.command]),
                    role: .create
                ),
                DeckKey(
                    position: 1,
                    label: "Close Tab",
                    iconSystemName: "xmark.square",
                    action: .hotkey(key: "w", modifiers: [.command]),
                    role: .danger
                ),
                DeckKey(
                    position: 2,
                    label: "Reopen",
                    iconSystemName: "arrow.uturn.backward.square",
                    action: .hotkey(key: "t", modifiers: [.command, .shift]),
                    role: .create
                ),
                DeckKey(
                    position: 3,
                    label: "Reload",
                    iconSystemName: "arrow.clockwise",
                    action: .hotkey(key: "r", modifiers: [.command]),
                    role: .run
                ),
                DeckKey(
                    position: 4,
                    label: "Reader",
                    iconSystemName: "doc.plaintext",
                    action: .hotkey(key: "r", modifiers: [.command, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 5,
                    label: "Back",
                    iconSystemName: "chevron.backward",
                    action: .hotkey(key: "[", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 6,
                    label: "Forward",
                    iconSystemName: "chevron.forward",
                    action: .hotkey(key: "]", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 7,
                    label: "Prev Tab",
                    iconSystemName: "chevron.left.square",
                    action: .hotkey(key: "tab", modifiers: [.control, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 8,
                    label: "Next Tab",
                    iconSystemName: "chevron.right.square",
                    action: .hotkey(key: "tab", modifiers: [.control]),
                    role: .navigate
                ),
                DeckKey(
                    position: 9,
                    label: "Tab Overview",
                    iconSystemName: "square.grid.2x2",
                    action: .hotkey(key: "\\", modifiers: [.command, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 10,
                    label: "Address Bar",
                    iconSystemName: "link",
                    action: .hotkey(key: "l", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 11,
                    label: "Bookmark",
                    iconSystemName: "bookmark",
                    action: .hotkey(key: "d", modifiers: [.command]),
                    role: .create
                ),
                DeckKey(
                    position: 12,
                    label: "Reading List",
                    iconSystemName: "eyeglasses",
                    action: .hotkey(key: "d", modifiers: [.command, .shift]),
                    role: .create
                ),
                DeckKey(
                    position: 13,
                    label: "Downloads",
                    iconSystemName: "arrow.down.circle",
                    action: .hotkey(key: "l", modifiers: [.command, .option]),
                    role: .navigate
                ),
                DeckKey(
                    position: 14,
                    label: "Private",
                    iconSystemName: "hand.raised",
                    action: .hotkey(key: "n", modifiers: [.command, .shift]),
                    role: .create
                )
            ]
        )
    }

    /// Finder (``com.apple.finder``). Shortcuts from Finder's menu bar.
    public static func makeFinderProfile() -> DeckProfile {
        DeckProfile(
            id: "com.apple.finder",
            appBundleIdentifier: "com.apple.finder",
            appName: "Finder",
            rows: 3,
            columns: 5,
            keys: [
                DeckKey(
                    position: 0,
                    label: "New Window",
                    iconSystemName: "macwindow.badge.plus",
                    action: .hotkey(key: "n", modifiers: [.command]),
                    role: .create
                ),
                DeckKey(
                    position: 1,
                    label: "New Folder",
                    iconSystemName: "folder.badge.plus",
                    action: .hotkey(key: "n", modifiers: [.command, .shift]),
                    role: .create
                ),
                DeckKey(
                    position: 2,
                    label: "New Tab",
                    iconSystemName: "plus.square",
                    action: .hotkey(key: "t", modifiers: [.command]),
                    role: .create
                ),
                DeckKey(
                    position: 3,
                    label: "Get Info",
                    iconSystemName: "info.circle",
                    action: .hotkey(key: "i", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 4,
                    label: "Quick Look",
                    iconSystemName: "eye",
                    action: .hotkey(key: "y", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 5,
                    label: "Duplicate",
                    iconSystemName: "plus.square.on.square",
                    action: .hotkey(key: "d", modifiers: [.command]),
                    role: .create
                ),
                DeckKey(
                    position: 6,
                    label: "Move to Trash",
                    iconSystemName: "trash",
                    action: .hotkey(key: "delete", modifiers: [.command]),
                    role: .danger
                ),
                DeckKey(
                    position: 7,
                    label: "Find",
                    iconSystemName: "magnifyingglass",
                    action: .hotkey(key: "f", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 8,
                    label: "Back",
                    iconSystemName: "chevron.backward",
                    action: .hotkey(key: "[", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 9,
                    label: "Forward",
                    iconSystemName: "chevron.forward",
                    action: .hotkey(key: "]", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 10,
                    label: "Up a Folder",
                    iconSystemName: "arrow.up.to.line",
                    action: .hotkey(key: "up", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 11,
                    label: "Downloads",
                    iconSystemName: "arrow.down.circle",
                    action: .hotkey(key: "l", modifiers: [.command, .option]),
                    role: .navigate
                ),
                DeckKey(
                    position: 12,
                    label: "Desktop",
                    iconSystemName: "menubar.dock.rectangle",
                    action: .hotkey(key: "d", modifiers: [.command, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 13,
                    label: "Home",
                    iconSystemName: "house",
                    action: .hotkey(key: "h", modifiers: [.command, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 14,
                    label: "AirDrop",
                    iconSystemName: "dot.radiowaves.left.and.right",
                    action: .hotkey(key: "r", modifiers: [.command, .shift]),
                    role: .navigate
                )
            ]
        )
    }

    /// Apple Mail (``com.apple.mail``). Shortcuts from Mail's menu bar.
    public static func makeMailProfile() -> DeckProfile {
        DeckProfile(
            id: "com.apple.mail",
            appBundleIdentifier: "com.apple.mail",
            appName: "Mail",
            rows: 3,
            columns: 5,
            keys: [
                DeckKey(
                    position: 0,
                    label: "New Message",
                    iconSystemName: "square.and.pencil",
                    action: .hotkey(key: "n", modifiers: [.command]),
                    role: .create
                ),
                DeckKey(
                    position: 1,
                    label: "Reply",
                    iconSystemName: "arrowshape.turn.up.left",
                    action: .hotkey(key: "r", modifiers: [.command]),
                    role: .create
                ),
                DeckKey(
                    position: 2,
                    label: "Reply All",
                    iconSystemName: "arrowshape.turn.up.left.2",
                    action: .hotkey(key: "r", modifiers: [.command, .shift]),
                    role: .create
                ),
                DeckKey(
                    position: 3,
                    label: "Forward",
                    iconSystemName: "arrowshape.turn.up.right",
                    action: .hotkey(key: "f", modifiers: [.command, .shift]),
                    role: .create
                ),
                DeckKey(
                    position: 4,
                    label: "Send",
                    iconSystemName: "paperplane",
                    action: .hotkey(key: "d", modifiers: [.command, .shift]),
                    role: .run
                ),
                DeckKey(
                    position: 5,
                    label: "Archive",
                    iconSystemName: "archivebox",
                    action: .hotkey(key: "a", modifiers: [.command, .control]),
                    role: .modify
                ),
                DeckKey(
                    position: 6,
                    label: "Mark Read",
                    iconSystemName: "envelope.open",
                    action: .hotkey(key: "u", modifiers: [.command, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 7,
                    label: "Junk",
                    iconSystemName: "xmark.bin",
                    action: .hotkey(key: "j", modifiers: [.command, .shift]),
                    role: .danger
                ),
                DeckKey(
                    position: 8,
                    label: "Get Mail",
                    iconSystemName: "arrow.down.circle",
                    action: .hotkey(key: "n", modifiers: [.command, .shift]),
                    role: .run
                ),
                DeckKey(
                    position: 9,
                    label: "Prev Unread",
                    iconSystemName: "chevron.up",
                    action: .hotkey(key: "[", modifiers: [.command, .control, .option]),
                    role: .navigate
                ),
                DeckKey(
                    position: 10,
                    label: "Next Unread",
                    iconSystemName: "chevron.down",
                    action: .hotkey(key: "]", modifiers: [.command, .control, .option]),
                    role: .navigate
                ),
                DeckKey(
                    position: 11,
                    label: "Attach",
                    iconSystemName: "paperclip",
                    action: .hotkey(key: "a", modifiers: [.command, .shift]),
                    role: .create
                ),
                DeckKey(
                    position: 12,
                    label: "Mute Thread",
                    iconSystemName: "bell.slash",
                    action: .hotkey(key: "m", modifiers: [.control, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 13,
                    label: "Sidebar",
                    iconSystemName: "sidebar.left",
                    action: .hotkey(key: "s", modifiers: [.command, .control]),
                    role: .navigate
                ),
                DeckKey(
                    position: 14,
                    label: "Viewer",
                    iconSystemName: "tray.full",
                    action: .hotkey(key: "0", modifiers: [.command]),
                    role: .navigate
                )
            ]
        )
    }

    /// Apple Messages (``com.apple.MobileSMS``). Shortcuts from Messages' menu bar.
    public static func makeMessagesProfile() -> DeckProfile {
        DeckProfile(
            id: "com.apple.MobileSMS",
            appBundleIdentifier: "com.apple.MobileSMS",
            appName: "Messages",
            rows: 3,
            columns: 5,
            keys: [
                DeckKey(
                    position: 0,
                    label: "New Message",
                    iconSystemName: "square.and.pencil",
                    action: .hotkey(key: "n", modifiers: [.command]),
                    role: .create
                ),
                DeckKey(
                    position: 1,
                    label: "Reply",
                    iconSystemName: "arrowshape.turn.up.left",
                    action: .hotkey(key: "r", modifiers: [.command]),
                    role: .create
                ),
                DeckKey(
                    position: 2,
                    label: "Tapback",
                    iconSystemName: "hand.thumbsup",
                    action: .hotkey(key: "t", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 3,
                    label: "Edit Last",
                    iconSystemName: "pencil",
                    action: .hotkey(key: "e", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 4,
                    label: "Send Later",
                    iconSystemName: "clock",
                    action: .hotkey(key: "l", modifiers: [.command]),
                    role: .run
                ),
                DeckKey(
                    position: 5,
                    label: "Prev Chat",
                    iconSystemName: "chevron.up",
                    action: .hotkey(key: "tab", modifiers: [.control, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 6,
                    label: "Next Chat",
                    iconSystemName: "chevron.down",
                    action: .hotkey(key: "tab", modifiers: [.control]),
                    role: .navigate
                ),
                DeckKey(
                    position: 7,
                    label: "Mark Unread",
                    iconSystemName: "envelope.badge",
                    action: .hotkey(key: "u", modifiers: [.command, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 8,
                    label: "All Read",
                    iconSystemName: "checkmark.circle",
                    action: .hotkey(key: "u", modifiers: [.command, .shift, .option]),
                    role: .modify
                ),
                DeckKey(
                    position: 9,
                    label: "Details",
                    iconSystemName: "info.circle",
                    action: .hotkey(key: "i", modifiers: [.command, .option]),
                    role: .navigate
                ),
                DeckKey(
                    position: 10,
                    label: "Contact",
                    iconSystemName: "person.crop.circle",
                    action: .hotkey(key: "b", modifiers: [.command, .option]),
                    role: .navigate
                ),
                DeckKey(
                    position: 11,
                    label: "Unread",
                    iconSystemName: "envelope",
                    action: .hotkey(key: "u", modifiers: [.command, .control]),
                    role: .navigate
                ),
                DeckKey(
                    position: 12,
                    label: "All Messages",
                    iconSystemName: "bubble.left.and.bubble.right",
                    action: .hotkey(key: "1", modifiers: [.command, .control]),
                    role: .navigate
                ),
                DeckKey(
                    position: 13,
                    label: "Bigger Text",
                    iconSystemName: "textformat.size.larger",
                    action: .hotkey(key: "=", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 14,
                    label: "Smaller Text",
                    iconSystemName: "textformat.size.smaller",
                    action: .hotkey(key: "-", modifiers: [.command]),
                    role: .modify
                )
            ]
        )
    }

    /// Microsoft Excel (``com.microsoft.Excel``). New and Save from Excel's menu bar; the rest from
    /// Microsoft's published "Keyboard shortcuts in Excel" (macOS).
    public static func makeExcelProfile() -> DeckProfile {
        DeckProfile(
            id: "com.microsoft.Excel",
            appBundleIdentifier: "com.microsoft.Excel",
            appName: "Excel",
            rows: 3,
            columns: 5,
            keys: [
                DeckKey(
                    position: 0,
                    label: "New",
                    iconSystemName: "doc.badge.plus",
                    action: .hotkey(key: "n", modifiers: [.command]),
                    role: .create
                ),
                DeckKey(
                    position: 1,
                    label: "Save",
                    iconSystemName: "square.and.arrow.down",
                    action: .hotkey(key: "s", modifiers: [.command]),
                    role: .run
                ),
                DeckKey(
                    position: 2,
                    label: "AutoSum",
                    iconSystemName: "sum",
                    action: .hotkey(key: "t", modifiers: [.command, .shift]),
                    role: .run
                ),
                DeckKey(
                    position: 3,
                    label: "Fill Down",
                    iconSystemName: "arrow.down.to.line",
                    action: .hotkey(key: "d", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 4,
                    label: "Fill Right",
                    iconSystemName: "arrow.right.to.line",
                    action: .hotkey(key: "r", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 5,
                    label: "Format Cells",
                    iconSystemName: "tablecells",
                    action: .hotkey(key: "1", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 6,
                    label: "Filter",
                    iconSystemName: "line.3.horizontal.decrease.circle",
                    action: .hotkey(key: "f", modifiers: [.command, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 7,
                    label: "Insert Cells",
                    iconSystemName: "plus.rectangle",
                    action: .hotkey(key: "=", modifiers: [.control, .shift]),
                    role: .create
                ),
                DeckKey(
                    position: 8,
                    label: "Delete Cells",
                    iconSystemName: "minus.rectangle",
                    action: .hotkey(key: "-", modifiers: [.command]),
                    role: .danger
                ),
                DeckKey(
                    position: 9,
                    label: "Today's Date",
                    iconSystemName: "calendar",
                    action: .hotkey(key: ";", modifiers: [.control]),
                    role: .create
                ),
                DeckKey(
                    position: 10,
                    label: "Current Time",
                    iconSystemName: "clock",
                    action: .hotkey(key: ";", modifiers: [.command]),
                    role: .create
                ),
                DeckKey(
                    position: 11,
                    label: "Create Table",
                    iconSystemName: "tablecells.badge.ellipsis",
                    action: .hotkey(key: "t", modifiers: [.command]),
                    role: .create
                ),
                DeckKey(
                    position: 12,
                    label: "Go To",
                    iconSystemName: "arrow.right.circle",
                    action: .hotkey(key: "g", modifiers: [.control]),
                    role: .navigate
                ),
                DeckKey(
                    position: 13,
                    label: "Insert Fn",
                    iconSystemName: "function",
                    action: .hotkey(key: "f3", modifiers: [.shift]),
                    role: .create
                ),
                DeckKey(
                    position: 14,
                    label: "Show Formulas",
                    iconSystemName: "eye",
                    action: .hotkey(key: "`", modifiers: [.control]),
                    role: .navigate
                )
            ]
        )
    }

    /// Microsoft PowerPoint (``com.microsoft.Powerpoint``). Shortcuts from PowerPoint's menu bar.
    public static func makePowerPointProfile() -> DeckProfile {
        DeckProfile(
            id: "com.microsoft.Powerpoint",
            appBundleIdentifier: "com.microsoft.Powerpoint",
            appName: "PowerPoint",
            rows: 3,
            columns: 5,
            keys: [
                DeckKey(
                    position: 0,
                    label: "New Slide",
                    iconSystemName: "plus.rectangle.on.rectangle",
                    action: .hotkey(key: "n", modifiers: [.command, .shift]),
                    role: .create
                ),
                DeckKey(
                    position: 1,
                    label: "Dup Slide",
                    iconSystemName: "plus.square.on.square",
                    action: .hotkey(key: "d", modifiers: [.command, .shift]),
                    role: .create
                ),
                DeckKey(
                    position: 2,
                    label: "Play Start",
                    iconSystemName: "play.fill",
                    action: .hotkey(key: "return", modifiers: [.command, .shift]),
                    role: .run
                ),
                DeckKey(
                    position: 3,
                    label: "Play Current",
                    iconSystemName: "play",
                    action: .hotkey(key: "return", modifiers: [.command]),
                    role: .run
                ),
                DeckKey(
                    position: 4,
                    label: "Presenter",
                    iconSystemName: "person.wave.2",
                    action: .hotkey(key: "return", modifiers: [.option]),
                    role: .run
                ),
                DeckKey(
                    position: 5,
                    label: "Normal View",
                    iconSystemName: "rectangle",
                    action: .hotkey(key: "1", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 6,
                    label: "Slide Sorter",
                    iconSystemName: "square.grid.3x2",
                    action: .hotkey(key: "2", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 7,
                    label: "Notes Page",
                    iconSystemName: "note.text",
                    action: .hotkey(key: "3", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 8,
                    label: "Comment",
                    iconSystemName: "text.bubble",
                    action: .hotkey(key: "m", modifiers: [.command, .shift]),
                    role: .create
                ),
                DeckKey(
                    position: 9,
                    label: "Hyperlink",
                    iconSystemName: "link",
                    action: .hotkey(key: "k", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 10,
                    label: "Group",
                    iconSystemName: "square.on.square",
                    action: .hotkey(key: "g", modifiers: [.command, .option]),
                    role: .modify
                ),
                DeckKey(
                    position: 11,
                    label: "Ungroup",
                    iconSystemName: "square.dashed",
                    action: .hotkey(key: "g", modifiers: [.command, .option, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 12,
                    label: "To Front",
                    iconSystemName: "square.3.layers.3d.top.filled",
                    action: .hotkey(key: "f", modifiers: [.command, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 13,
                    label: "To Back",
                    iconSystemName: "square.3.layers.3d.bottom.filled",
                    action: .hotkey(key: "b", modifiers: [.command, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 14,
                    label: "Save",
                    iconSystemName: "square.and.arrow.down",
                    action: .hotkey(key: "s", modifiers: [.command]),
                    role: .run
                )
            ]
        )
    }

    /// Microsoft Outlook (``com.microsoft.Outlook``). Shortcuts from Microsoft's published "Keyboard
    /// shortcuts in Outlook for Mac".
    public static func makeOutlookProfile() -> DeckProfile {
        DeckProfile(
            id: "com.microsoft.Outlook",
            appBundleIdentifier: "com.microsoft.Outlook",
            appName: "Outlook",
            rows: 3,
            columns: 5,
            keys: [
                DeckKey(
                    position: 0,
                    label: "New Message",
                    iconSystemName: "square.and.pencil",
                    action: .hotkey(key: "n", modifiers: [.command]),
                    role: .create
                ),
                DeckKey(
                    position: 1,
                    label: "Send",
                    iconSystemName: "paperplane",
                    action: .hotkey(key: "return", modifiers: [.command]),
                    role: .run
                ),
                DeckKey(
                    position: 2,
                    label: "Reply",
                    iconSystemName: "arrowshape.turn.up.left",
                    action: .hotkey(key: "r", modifiers: [.command]),
                    role: .create
                ),
                DeckKey(
                    position: 3,
                    label: "Reply All",
                    iconSystemName: "arrowshape.turn.up.left.2",
                    action: .hotkey(key: "r", modifiers: [.command, .shift]),
                    role: .create
                ),
                DeckKey(
                    position: 4,
                    label: "Forward",
                    iconSystemName: "arrowshape.turn.up.right",
                    action: .hotkey(key: "j", modifiers: [.command]),
                    role: .create
                ),
                DeckKey(
                    position: 5,
                    label: "Mark Read",
                    iconSystemName: "envelope.open",
                    action: .hotkey(key: "t", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 6,
                    label: "Mark Unread",
                    iconSystemName: "envelope.badge",
                    action: .hotkey(key: "t", modifiers: [.command, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 7,
                    label: "Archive",
                    iconSystemName: "archivebox",
                    action: .hotkey(key: "e", modifiers: [.control]),
                    role: .modify
                ),
                DeckKey(
                    position: 8,
                    label: "Delete",
                    iconSystemName: "trash",
                    action: .hotkey(key: "delete", modifiers: []),
                    role: .danger
                ),
                DeckKey(
                    position: 9,
                    label: "Flag",
                    iconSystemName: "flag",
                    action: .hotkey(key: "1", modifiers: [.control]),
                    role: .modify
                ),
                DeckKey(
                    position: 10,
                    label: "Mail",
                    iconSystemName: "envelope",
                    action: .hotkey(key: "1", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 11,
                    label: "Calendar",
                    iconSystemName: "calendar",
                    action: .hotkey(key: "2", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 12,
                    label: "Contacts",
                    iconSystemName: "person.2",
                    action: .hotkey(key: "3", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 13,
                    label: "Search",
                    iconSystemName: "magnifyingglass",
                    action: .hotkey(key: "f", modifiers: [.command, .option]),
                    role: .navigate
                ),
                DeckKey(
                    position: 14,
                    label: "Sync",
                    iconSystemName: "arrow.triangle.2.circlepath",
                    action: .hotkey(key: "k", modifiers: [.command, .control]),
                    role: .run
                )
            ]
        )
    }

    /// Microsoft Teams (``com.microsoft.teams2``). Settings from Teams' menu bar; the rest from Microsoft's
    /// published "Keyboard shortcuts for Microsoft Teams" (macOS).
    public static func makeTeamsProfile() -> DeckProfile {
        DeckProfile(
            id: "com.microsoft.teams2",
            appBundleIdentifier: "com.microsoft.teams2",
            appName: "Teams",
            rows: 3,
            columns: 5,
            keys: [
                DeckKey(
                    position: 0,
                    label: "New Chat",
                    iconSystemName: "square.and.pencil",
                    action: .hotkey(key: "n", modifiers: [.command]),
                    role: .create
                ),
                DeckKey(
                    position: 1,
                    label: "Search",
                    iconSystemName: "magnifyingglass",
                    action: .hotkey(key: "e", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 2,
                    label: "Calendar",
                    iconSystemName: "calendar",
                    action: .hotkey(key: "2", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 3,
                    label: "Mute",
                    iconSystemName: "mic.slash",
                    action: .hotkey(key: "m", modifiers: [.command, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 4,
                    label: "Video",
                    iconSystemName: "video",
                    action: .hotkey(key: "o", modifiers: [.command, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 5,
                    label: "Raise Hand",
                    iconSystemName: "hand.raised",
                    action: .hotkey(key: "k", modifiers: [.command, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 6,
                    label: "Share Tray",
                    iconSystemName: "rectangle.on.rectangle",
                    action: .hotkey(key: "e", modifiers: [.command, .shift]),
                    role: .run
                ),
                DeckKey(
                    position: 7,
                    label: "End Call",
                    iconSystemName: "phone.down.fill",
                    action: .hotkey(key: "h", modifiers: [.command, .shift]),
                    role: .danger,
                    requiresConfirm: true
                ),
                DeckKey(
                    position: 8,
                    label: "Accept Video",
                    iconSystemName: "video.badge.checkmark",
                    action: .hotkey(key: "v", modifiers: [.command, .shift]),
                    role: .run
                ),
                DeckKey(
                    position: 9,
                    label: "Accept Audio",
                    iconSystemName: "phone.arrow.down.left",
                    action: .hotkey(key: "a", modifiers: [.command, .shift]),
                    role: .run
                ),
                DeckKey(
                    position: 10,
                    label: "Decline",
                    iconSystemName: "phone.down.circle",
                    action: .hotkey(key: "d", modifiers: [.command, .shift]),
                    role: .danger
                ),
                DeckKey(
                    position: 11,
                    label: "Shortcuts",
                    iconSystemName: "keyboard",
                    action: .hotkey(key: ".", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 12,
                    label: "Settings",
                    iconSystemName: "gearshape",
                    action: .hotkey(key: ",", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 13,
                    label: "Next Section",
                    iconSystemName: "arrow.right.square",
                    action: .hotkey(key: "f6", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 14,
                    label: "Prev Section",
                    iconSystemName: "arrow.left.square",
                    action: .hotkey(key: "f6", modifiers: [.command, .shift]),
                    role: .navigate
                )
            ]
        )
    }

    /// Slack (``com.tinyspeck.slackmacgap``). Shortcuts from Slack's published "Slack keyboard shortcuts" (Mac).
    public static func makeSlackProfile() -> DeckProfile {
        DeckProfile(
            id: "com.tinyspeck.slackmacgap",
            appBundleIdentifier: "com.tinyspeck.slackmacgap",
            appName: "Slack",
            rows: 3,
            columns: 5,
            keys: [
                DeckKey(
                    position: 0,
                    label: "New Message",
                    iconSystemName: "square.and.pencil",
                    action: .hotkey(key: "n", modifiers: [.command]),
                    role: .create
                ),
                DeckKey(
                    position: 1,
                    label: "Jump To",
                    iconSystemName: "arrow.right.circle",
                    action: .hotkey(key: "k", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 2,
                    label: "Search",
                    iconSystemName: "magnifyingglass",
                    action: .hotkey(key: "g", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 3,
                    label: "All Unreads",
                    iconSystemName: "tray.full",
                    action: .hotkey(key: "a", modifiers: [.command, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 4,
                    label: "Threads",
                    iconSystemName: "bubble.left.and.bubble.right",
                    action: .hotkey(key: "t", modifiers: [.command, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 5,
                    label: "Activity",
                    iconSystemName: "at",
                    action: .hotkey(key: "m", modifiers: [.command, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 6,
                    label: "Prev Unread",
                    iconSystemName: "chevron.up",
                    action: .hotkey(key: "up", modifiers: [.option, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 7,
                    label: "Next Unread",
                    iconSystemName: "chevron.down",
                    action: .hotkey(key: "down", modifiers: [.option, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 8,
                    label: "Browse DMs",
                    iconSystemName: "person.2",
                    action: .hotkey(key: "k", modifiers: [.command, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 9,
                    label: "Channels",
                    iconSystemName: "number",
                    action: .hotkey(key: "l", modifiers: [.command, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 10,
                    label: "Huddle",
                    iconSystemName: "headphones",
                    action: .hotkey(key: "h", modifiers: [.command, .shift]),
                    role: .run
                ),
                DeckKey(
                    position: 11,
                    label: "Set Status",
                    iconSystemName: "face.smiling",
                    action: .hotkey(key: "y", modifiers: [.command, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 12,
                    label: "Upload",
                    iconSystemName: "paperclip",
                    action: .hotkey(key: "o", modifiers: [.command]),
                    role: .create
                ),
                DeckKey(
                    position: 13,
                    label: "Mark Read",
                    iconSystemName: "checkmark",
                    action: .hotkey(key: "escape", modifiers: []),
                    role: .modify
                ),
                DeckKey(
                    position: 14,
                    label: "All Read",
                    iconSystemName: "checkmark.circle",
                    action: .hotkey(key: "escape", modifiers: [.shift]),
                    role: .modify
                )
            ]
        )
    }

    /// Spotify (``com.spotify.client``). Shortcuts from Spotify's published keyboard shortcuts (Mac).
    public static func makeSpotifyProfile() -> DeckProfile {
        DeckProfile(
            id: "com.spotify.client",
            appBundleIdentifier: "com.spotify.client",
            appName: "Spotify",
            rows: 3,
            columns: 5,
            keys: [
                DeckKey(
                    position: 0,
                    label: "Play/Pause",
                    iconSystemName: "playpause.fill",
                    action: .hotkey(key: "space", modifiers: []),
                    role: .run
                ),
                DeckKey(
                    position: 1,
                    label: "Like",
                    iconSystemName: "heart",
                    action: .hotkey(key: "b", modifiers: [.option, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 2,
                    label: "Shuffle",
                    iconSystemName: "shuffle",
                    action: .hotkey(key: "s", modifiers: [.option]),
                    role: .modify
                ),
                DeckKey(
                    position: 3,
                    label: "Repeat",
                    iconSystemName: "repeat",
                    action: .hotkey(key: "r", modifiers: [.option]),
                    role: .modify
                ),
                DeckKey(
                    position: 4,
                    label: "Mute",
                    iconSystemName: "speaker.slash",
                    action: .hotkey(key: "m", modifiers: []),
                    role: .modify
                ),
                DeckKey(
                    position: 5,
                    label: "Search",
                    iconSystemName: "magnifyingglass",
                    action: .hotkey(key: "k", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 6,
                    label: "Home",
                    iconSystemName: "house",
                    action: .hotkey(key: "h", modifiers: [.option, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 7,
                    label: "Library",
                    iconSystemName: "books.vertical",
                    action: .hotkey(key: "0", modifiers: [.option, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 8,
                    label: "Liked Songs",
                    iconSystemName: "heart.fill",
                    action: .hotkey(key: "s", modifiers: [.option, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 9,
                    label: "Queue",
                    iconSystemName: "list.bullet",
                    action: .hotkey(key: "q", modifiers: [.option, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 10,
                    label: "Playlists",
                    iconSystemName: "music.note.list",
                    action: .hotkey(key: "1", modifiers: [.option, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 11,
                    label: "Podcasts",
                    iconSystemName: "mic",
                    action: .hotkey(key: "2", modifiers: [.option, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 12,
                    label: "Albums",
                    iconSystemName: "square.stack",
                    action: .hotkey(key: "4", modifiers: [.option, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 13,
                    label: "Add to Queue",
                    iconSystemName: "text.badge.plus",
                    action: .hotkey(key: "right", modifiers: []),
                    role: .create
                ),
                DeckKey(
                    position: 14,
                    label: "Settings",
                    iconSystemName: "gearshape",
                    action: .hotkey(key: ",", modifiers: [.command]),
                    role: .navigate
                )
            ]
        )
    }

    /// Apple Notes (``com.apple.Notes``). Shortcuts from Notes' menu bar.
    public static func makeNotesProfile() -> DeckProfile {
        DeckProfile(
            id: "com.apple.Notes",
            appBundleIdentifier: "com.apple.Notes",
            appName: "Notes",
            rows: 3,
            columns: 5,
            keys: [
                DeckKey(
                    position: 0,
                    label: "New Note",
                    iconSystemName: "square.and.pencil",
                    action: .hotkey(key: "n", modifiers: [.command]),
                    role: .create
                ),
                DeckKey(
                    position: 1,
                    label: "New Folder",
                    iconSystemName: "folder.badge.plus",
                    action: .hotkey(key: "n", modifiers: [.command, .shift]),
                    role: .create
                ),
                DeckKey(
                    position: 2,
                    label: "Duplicate",
                    iconSystemName: "plus.square.on.square",
                    action: .hotkey(key: "d", modifiers: [.command]),
                    role: .create
                ),
                DeckKey(
                    position: 3,
                    label: "Checklist",
                    iconSystemName: "checklist",
                    action: .hotkey(key: "l", modifiers: [.command, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 4,
                    label: "Check Item",
                    iconSystemName: "checkmark.circle",
                    action: .hotkey(key: "u", modifiers: [.command, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 5,
                    label: "Title",
                    iconSystemName: "textformat.size.larger",
                    action: .hotkey(key: "t", modifiers: [.command, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 6,
                    label: "Heading",
                    iconSystemName: "textformat",
                    action: .hotkey(key: "h", modifiers: [.command, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 7,
                    label: "Body",
                    iconSystemName: "text.alignleft",
                    action: .hotkey(key: "b", modifiers: [.command, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 8,
                    label: "Bullets",
                    iconSystemName: "list.bullet",
                    action: .hotkey(key: "7", modifiers: [.command, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 9,
                    label: "Numbered",
                    iconSystemName: "list.number",
                    action: .hotkey(key: "9", modifiers: [.command, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 10,
                    label: "Table",
                    iconSystemName: "tablecells",
                    action: .hotkey(key: "t", modifiers: [.command, .option]),
                    role: .create
                ),
                DeckKey(
                    position: 11,
                    label: "Link",
                    iconSystemName: "link",
                    action: .hotkey(key: "k", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 12,
                    label: "Attach",
                    iconSystemName: "paperclip",
                    action: .hotkey(key: "a", modifiers: [.command, .shift]),
                    role: .create
                ),
                DeckKey(
                    position: 13,
                    label: "List View",
                    iconSystemName: "list.bullet.rectangle",
                    action: .hotkey(key: "1", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 14,
                    label: "Gallery",
                    iconSystemName: "square.grid.2x2",
                    action: .hotkey(key: "2", modifiers: [.command]),
                    role: .navigate
                )
            ]
        )
    }

    /// Apple Calendar (``com.apple.iCal``). Shortcuts from Calendar's menu bar.
    public static func makeCalendarProfile() -> DeckProfile {
        DeckProfile(
            id: "com.apple.iCal",
            appBundleIdentifier: "com.apple.iCal",
            appName: "Calendar",
            rows: 3,
            columns: 5,
            keys: [
                DeckKey(
                    position: 0,
                    label: "New Event",
                    iconSystemName: "plus.circle",
                    action: .hotkey(key: "n", modifiers: [.command]),
                    role: .create
                ),
                DeckKey(
                    position: 1,
                    label: "Today",
                    iconSystemName: "calendar.circle",
                    action: .hotkey(key: "t", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 2,
                    label: "Go to Date",
                    iconSystemName: "calendar.badge.clock",
                    action: .hotkey(key: "t", modifiers: [.command, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 3,
                    label: "Day",
                    iconSystemName: "1.square",
                    action: .hotkey(key: "1", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 4,
                    label: "Week",
                    iconSystemName: "7.square",
                    action: .hotkey(key: "2", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 5,
                    label: "Month",
                    iconSystemName: "calendar",
                    action: .hotkey(key: "3", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 6,
                    label: "Year",
                    iconSystemName: "square.grid.3x3",
                    action: .hotkey(key: "4", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 7,
                    label: "Previous",
                    iconSystemName: "chevron.backward",
                    action: .hotkey(key: "left", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 8,
                    label: "Next",
                    iconSystemName: "chevron.forward",
                    action: .hotkey(key: "right", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 9,
                    label: "Find",
                    iconSystemName: "magnifyingglass",
                    action: .hotkey(key: "f", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 10,
                    label: "Edit Event",
                    iconSystemName: "pencil",
                    action: .hotkey(key: "e", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 11,
                    label: "Get Info",
                    iconSystemName: "info.circle",
                    action: .hotkey(key: "i", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 12,
                    label: "Duplicate",
                    iconSystemName: "plus.square.on.square",
                    action: .hotkey(key: "d", modifiers: [.command]),
                    role: .create
                ),
                DeckKey(
                    position: 13,
                    label: "Refresh",
                    iconSystemName: "arrow.clockwise",
                    action: .hotkey(key: "r", modifiers: [.command]),
                    role: .run
                ),
                DeckKey(
                    position: 14,
                    label: "Availability",
                    iconSystemName: "person.2.badge.gearshape",
                    action: .hotkey(key: "a", modifiers: [.command, .shift]),
                    role: .navigate
                )
            ]
        )
    }

    /// Apple Music (``com.apple.Music``). Shortcuts from Music's menu bar.
    public static func makeMusicProfile() -> DeckProfile {
        DeckProfile(
            id: "com.apple.Music",
            appBundleIdentifier: "com.apple.Music",
            appName: "Music",
            rows: 3,
            columns: 5,
            keys: [
                DeckKey(
                    position: 0,
                    label: "Play/Pause",
                    iconSystemName: "playpause.fill",
                    action: .hotkey(key: "space", modifiers: []),
                    role: .run
                ),
                DeckKey(
                    position: 1,
                    label: "Previous",
                    iconSystemName: "backward.fill",
                    action: .hotkey(key: "left", modifiers: [.command]),
                    role: .run
                ),
                DeckKey(
                    position: 2,
                    label: "Next",
                    iconSystemName: "forward.fill",
                    action: .hotkey(key: "right", modifiers: [.command]),
                    role: .run
                ),
                DeckKey(
                    position: 3,
                    label: "Stop",
                    iconSystemName: "stop.fill",
                    action: .hotkey(key: ".", modifiers: [.command]),
                    role: .danger
                ),
                DeckKey(
                    position: 4,
                    label: "Volume Up",
                    iconSystemName: "speaker.plus",
                    action: .hotkey(key: "up", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 5,
                    label: "Volume Down",
                    iconSystemName: "speaker.minus",
                    action: .hotkey(key: "down", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 6,
                    label: "Genius Shuffle",
                    iconSystemName: "shuffle",
                    action: .hotkey(key: "space", modifiers: [.option]),
                    role: .modify
                ),
                DeckKey(
                    position: 7,
                    label: "Current Song",
                    iconSystemName: "music.note",
                    action: .hotkey(key: "l", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 8,
                    label: "Playing Next",
                    iconSystemName: "list.bullet",
                    action: .hotkey(key: "u", modifiers: [.command, .option]),
                    role: .navigate
                ),
                DeckKey(
                    position: 9,
                    label: "Lyrics",
                    iconSystemName: "quote.bubble",
                    action: .hotkey(key: "u", modifiers: [.command, .control]),
                    role: .navigate
                ),
                DeckKey(
                    position: 10,
                    label: "MiniPlayer",
                    iconSystemName: "rectangle.compress.vertical",
                    action: .hotkey(key: "m", modifiers: [.command, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 11,
                    label: "Now Playing",
                    iconSystemName: "play.rectangle",
                    action: .hotkey(key: "f", modifiers: [.command, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 12,
                    label: "Equalizer",
                    iconSystemName: "slider.vertical.3",
                    action: .hotkey(key: "e", modifiers: [.command, .option]),
                    role: .navigate
                ),
                DeckKey(
                    position: 13,
                    label: "Get Info",
                    iconSystemName: "info.circle",
                    action: .hotkey(key: "i", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 14,
                    label: "Filter",
                    iconSystemName: "line.3.horizontal.decrease",
                    action: .hotkey(key: "f", modifiers: [.command, .option]),
                    role: .navigate
                )
            ]
        )
    }

    /// Apple Photos (``com.apple.Photos``). Shortcuts from Photos' menu bar.
    public static func makePhotosProfile() -> DeckProfile {
        DeckProfile(
            id: "com.apple.Photos",
            appBundleIdentifier: "com.apple.Photos",
            appName: "Photos",
            rows: 3,
            columns: 5,
            keys: [
                DeckKey(
                    position: 0,
                    label: "New Album",
                    iconSystemName: "rectangle.stack.badge.plus",
                    action: .hotkey(key: "n", modifiers: [.command]),
                    role: .create
                ),
                DeckKey(
                    position: 1,
                    label: "Import",
                    iconSystemName: "square.and.arrow.down",
                    action: .hotkey(key: "i", modifiers: [.command, .shift]),
                    role: .create
                ),
                DeckKey(
                    position: 2,
                    label: "Find",
                    iconSystemName: "magnifyingglass",
                    action: .hotkey(key: "f", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 3,
                    label: "Rotate Left",
                    iconSystemName: "rotate.left",
                    action: .hotkey(key: "r", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 4,
                    label: "Rotate Right",
                    iconSystemName: "rotate.right",
                    action: .hotkey(key: "r", modifiers: [.command, .option]),
                    role: .modify
                ),
                DeckKey(
                    position: 5,
                    label: "Enhance",
                    iconSystemName: "wand.and.stars",
                    action: .hotkey(key: "e", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 6,
                    label: "Favorite",
                    iconSystemName: "heart",
                    action: .hotkey(key: ".", modifiers: []),
                    role: .modify
                ),
                DeckKey(
                    position: 7,
                    label: "Edit",
                    iconSystemName: "slider.horizontal.3",
                    action: .hotkey(key: "return", modifiers: []),
                    role: .modify
                ),
                DeckKey(
                    position: 8,
                    label: "View",
                    iconSystemName: "eye",
                    action: .hotkey(key: "space", modifiers: []),
                    role: .navigate
                ),
                DeckKey(
                    position: 9,
                    label: "Hide",
                    iconSystemName: "eye.slash",
                    action: .hotkey(key: "l", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 10,
                    label: "Delete",
                    iconSystemName: "trash",
                    action: .hotkey(key: "delete", modifiers: [.command]),
                    role: .danger
                ),
                DeckKey(
                    position: 11,
                    label: "Library",
                    iconSystemName: "photo.on.rectangle",
                    action: .hotkey(key: "1", modifiers: [.control]),
                    role: .navigate
                ),
                DeckKey(
                    position: 12,
                    label: "Collections",
                    iconSystemName: "square.grid.2x2",
                    action: .hotkey(key: "2", modifiers: [.control]),
                    role: .navigate
                ),
                DeckKey(
                    position: 13,
                    label: "Info",
                    iconSystemName: "info.circle",
                    action: .hotkey(key: "i", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 14,
                    label: "Zoom In",
                    iconSystemName: "plus.magnifyingglass",
                    action: .hotkey(key: "=", modifiers: [.command]),
                    role: .modify
                )
            ]
        )
    }

    /// Notion (``notion.id``). Shortcuts from Notion's published keyboard shortcuts (Mac); only nine
    /// page-level shortcuts are documented, so the rest of the grid stays empty.
    public static func makeNotionProfile() -> DeckProfile {
        DeckProfile(
            id: "notion.id",
            appBundleIdentifier: "notion.id",
            appName: "Notion",
            rows: 3,
            columns: 5,
            keys: [
                DeckKey(
                    position: 0,
                    label: "New Page",
                    iconSystemName: "doc.badge.plus",
                    action: .hotkey(key: "n", modifiers: [.command]),
                    role: .create
                ),
                DeckKey(
                    position: 1,
                    label: "Search",
                    iconSystemName: "magnifyingglass",
                    action: .hotkey(key: "p", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 2,
                    label: "Back",
                    iconSystemName: "chevron.backward",
                    action: .hotkey(key: "[", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 3,
                    label: "Forward",
                    iconSystemName: "chevron.forward",
                    action: .hotkey(key: "]", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 4,
                    label: "Copy Link",
                    iconSystemName: "link",
                    action: .hotkey(key: "l", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 5,
                    label: "New Window",
                    iconSystemName: "macwindow.badge.plus",
                    action: .hotkey(key: "n", modifiers: [.command, .shift]),
                    role: .create
                ),
                DeckKey(
                    position: 6,
                    label: "Dark Mode",
                    iconSystemName: "moon",
                    action: .hotkey(key: "l", modifiers: [.command, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 7,
                    label: "Comment",
                    iconSystemName: "text.bubble",
                    action: .hotkey(key: "m", modifiers: [.command, .shift]),
                    role: .create
                ),
                DeckKey(
                    position: 8,
                    label: "Duplicate",
                    iconSystemName: "plus.square.on.square",
                    action: .hotkey(key: "d", modifiers: [.command]),
                    role: .create
                )
            ]
        )
    }

    /// ChatGPT (``com.openai.chat``). Shortcuts from OpenAI's help articles for the macOS app; OpenAI
    /// documents only these six.
    public static func makeChatGPTProfile() -> DeckProfile {
        DeckProfile(
            id: "com.openai.chat",
            appBundleIdentifier: "com.openai.chat",
            appName: "ChatGPT",
            rows: 3,
            columns: 5,
            keys: [
                DeckKey(
                    position: 0,
                    label: "Chat Bar",
                    iconSystemName: "bubble.left",
                    action: .hotkey(key: "space", modifiers: [.option]),
                    role: .create
                ),
                DeckKey(
                    position: 1,
                    label: "Find",
                    iconSystemName: "magnifyingglass",
                    action: .hotkey(key: "f", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 2,
                    label: "Stop",
                    iconSystemName: "stop.circle",
                    action: .hotkey(key: ".", modifiers: [.command]),
                    role: .danger
                ),
                DeckKey(
                    position: 3,
                    label: "Share Desktop",
                    iconSystemName: "display",
                    action: .hotkey(key: "1", modifiers: [.command, .shift]),
                    role: .run
                ),
                DeckKey(
                    position: 4,
                    label: "Share Window",
                    iconSystemName: "macwindow",
                    action: .hotkey(key: "2", modifiers: [.command, .shift]),
                    role: .run
                ),
                DeckKey(
                    position: 5,
                    label: "Browser",
                    iconSystemName: "globe",
                    action: .hotkey(key: "b", modifiers: [.command, .shift]),
                    role: .navigate
                )
            ]
        )
    }

    /// Citrix Viewer (``com.citrix.receiver.icaviewer.mac``), the window of a Citrix session to a
    /// remote Windows desktop, as five modes: Windows, Outlook, Word, Excel and Teams. Sidekey
    /// cannot see which Windows app is in front inside the session, so the bottom row of every
    /// mode switches between them; the Mac remembers the mode and lights its key.
    ///
    /// Shortcuts from Microsoft's "Keyboard shortcuts in Windows" and the Windows shortcut pages
    /// for classic Outlook, Word, Excel and Teams; Outlook's Delete uses Ctrl+D, and Teams' Chat
    /// is the first app bar slot (Ctrl+1), both to be confirmed live. Win+Tab (Task View) is left
    /// out: macOS takes Command+Tab for its own app switcher before Citrix sees it (found live
    /// 2026-10-08). Sent through ``CitrixKeyMapper`` on the Mac, which assumes the Citrix keyboard
    /// settings it documents.
    ///
    /// :returns: The Windows mode first; it is the layout Citrix Viewer starts in.
    public static func makeCitrixViewerProfiles() -> [DeckProfile] {
        typealias Key = (label: String, icon: String, key: String, modifiers: [WindowsModifier], role: KeyRole, hold: Bool)
        let bundle = "com.citrix.receiver.icaviewer.mac"
        let modes: [(id: String, label: String, icon: String, keys: [Key])] = [
            (bundle, "Windows", "macwindow", [
                ("Start", "square.grid.2x2", "win", [], .navigate, false),
                ("Ctrl+Alt+Del", "lock.shield", "forwarddelete", [.ctrl, .alt], .navigate, false),
                ("File Explorer", "folder", "e", [.win], .navigate, false),
                ("Show Desktop", "menubar.dock.rectangle", "d", [.win], .navigate, false),
                ("Lock", "lock", "l", [.win], .danger, true),
                ("Switch App", "arrow.left.arrow.right.square", "tab", [.alt], .navigate, false),
                ("Snap Left", "rectangle.lefthalf.filled", "left", [.win], .modify, false),
                ("Snap Right", "rectangle.righthalf.filled", "right", [.win], .modify, false),
                ("Close App", "xmark.square", "f4", [.alt], .danger, true),
                ("Undo", "arrow.uturn.backward", "z", [.ctrl], .modify, false),
            ]),
            ("\(bundle).outlook", "Outlook", "envelope", [
                ("New Email", "square.and.pencil", "m", [.ctrl, .shift], .create, false),
                ("Reply", "arrowshape.turn.up.left", "r", [.ctrl], .create, false),
                ("Reply All", "arrowshape.turn.up.left.2", "r", [.ctrl, .shift], .create, false),
                ("Forward", "arrowshape.turn.up.right", "f", [.ctrl], .create, false),
                ("Send", "paperplane", "return", [.ctrl], .run, false),
                ("Mark Read", "envelope.open", "q", [.ctrl], .modify, false),
                ("Mark Unread", "envelope.badge", "u", [.ctrl], .modify, false),
                ("Delete", "trash", "d", [.ctrl], .danger, false),
                ("Mail", "tray", "1", [.ctrl], .navigate, false),
                ("Calendar", "calendar", "2", [.ctrl], .navigate, false),
            ]),
            ("\(bundle).word", "Word", "doc.text", [
                ("Save", "square.and.arrow.down", "s", [.ctrl], .run, false),
                ("Undo", "arrow.uturn.backward", "z", [.ctrl], .modify, false),
                ("Redo", "arrow.uturn.forward", "y", [.ctrl], .modify, false),
                ("Bold", "bold", "b", [.ctrl], .modify, false),
                ("Italic", "italic", "i", [.ctrl], .modify, false),
                ("Underline", "underline", "u", [.ctrl], .modify, false),
                ("Bullets", "list.bullet", "l", [.ctrl, .shift], .modify, false),
                ("Find", "magnifyingglass", "f", [.ctrl], .navigate, false),
                ("Comment", "text.bubble", "m", [.ctrl, .alt], .create, false),
                ("Track Changes", "pencil.and.outline", "e", [.ctrl, .shift], .modify, false),
            ]),
            ("\(bundle).excel", "Excel", "tablecells", [
                ("Save", "square.and.arrow.down", "s", [.ctrl], .run, false),
                ("Undo", "arrow.uturn.backward", "z", [.ctrl], .modify, false),
                ("AutoSum", "sum", "=", [.alt], .run, false),
                ("Fill Down", "arrow.down.to.line", "d", [.ctrl], .modify, false),
                ("Format Cells", "tablecells.badge.ellipsis", "1", [.ctrl], .modify, false),
                ("Filter", "line.3.horizontal.decrease.circle", "l", [.ctrl, .shift], .modify, false),
                ("Insert Cells", "plus.rectangle", "=", [.ctrl, .shift], .create, false),
                ("Delete Cells", "minus.rectangle", "-", [.ctrl], .danger, false),
                ("Edit Cell", "character.cursor.ibeam", "f2", [], .modify, false),
                ("Today's Date", "calendar", ";", [.ctrl], .create, false),
            ]),
            ("\(bundle).teams", "Teams", "person.2", [
                ("Mute", "mic.slash", "m", [.ctrl, .shift], .modify, false),
                ("Video", "video", "o", [.ctrl, .shift], .modify, false),
                ("Raise Hand", "hand.raised", "k", [.ctrl, .shift], .modify, false),
                ("Share", "rectangle.on.rectangle", "e", [.ctrl, .shift], .run, false),
                ("Leave", "phone.down.fill", "h", [.ctrl, .shift], .danger, true),
                ("Accept Call", "phone.arrow.down.left", "s", [.ctrl, .shift], .run, false),
                ("Decline", "phone.down.circle", "d", [.ctrl, .shift], .danger, false),
                ("New Chat", "square.and.pencil", "n", [.ctrl], .create, false),
                ("Search", "magnifyingglass", "e", [.ctrl], .navigate, false),
                ("Chat", "bubble.left.and.bubble.right", "1", [.ctrl], .navigate, false),
            ]),
        ]
        let modeRow = modes.enumerated().map { index, mode in
            DeckKey(position: 10 + index, label: mode.label,
                    iconSystemName: mode.icon, action: .switchProfile(profileId: mode.id), role: .navigate,
                    toggleChipId: "mode.\(mode.id)")
        }
        return modes.map { mode in
            let keys = mode.keys.enumerated().map { index, key in
                DeckKey(position: index, label: key.label, iconSystemName: key.icon,
                        action: .windowsHotkey(key: key.key, modifiers: key.modifiers), role: key.role, requiresConfirm: key.hold)
            }
            return DeckProfile(id: mode.id, appBundleIdentifier: bundle, appName: "Citrix Viewer", rows: 3, columns: 5, keys: keys + modeRow)
        }
    }
}
