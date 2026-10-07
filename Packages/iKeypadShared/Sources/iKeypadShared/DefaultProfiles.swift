import Foundation

public struct DefaultProfiles {
    public static func makeDefaultFallbackProfile() -> DeckProfile {
        return DeckProfile(
            // Stable across launches so a pinned layout survives a Mac companion restart.
            id: "default",
            appBundleIdentifier: "default",
            appName: "System",
            rows: 3,
            columns: 5,
            keys: [
                DeckKey(
                    position: 0,
                    label: "Mute Mic",
                    iconSystemName: "mic.slash.fill",
                    action: .appleScript(script: "set volume input volume 0"),
                    role: .modify
                ),
                DeckKey(
                    position: 1,
                    label: "Play/Pause",
                    iconSystemName: "playpause.fill",
                    action: .appleScript(script: "tell application \"Music\" to playpause"),
                    role: .run
                ),
                DeckKey(
                    position: 2,
                    label: "Screenshot",
                    iconSystemName: "camera.viewfinder",
                    action: .hotkey(key: "4", modifiers: [.command, .shift]),
                    role: .run
                ),
                DeckKey(
                    position: 3,
                    label: "Spotlight",
                    iconSystemName: "magnifyingglass",
                    action: .hotkey(key: "space", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 4,
                    label: "Lock Mac",
                    iconSystemName: "lock.fill",
                    action: .hotkey(key: "q", modifiers: [.command, .control]),
                    role: .danger,
                    requiresConfirm: true
                ),
                DeckKey(
                    position: 5,
                    label: "Terminal",
                    iconSystemName: "terminal.fill",
                    action: .shellScript(command: "open -a Terminal"),
                    role: .navigate
                ),
                DeckKey(
                    position: 6,
                    label: "Finder",
                    iconSystemName: "folder.fill",
                    action: .shellScript(command: "open -a Finder ~"),
                    role: .navigate
                ),
                DeckKey(
                    position: 7,
                    label: "Do Not Disturb",
                    iconSystemName: "moon.fill",
                    action: .runShortcut(name: "Toggle Focus"),
                    role: .modify
                )
            ]
        )
    }

    public static func makeVSCodeProfile() -> DeckProfile {
        return DeckProfile(
            // Stable across launches so a pinned layout survives a Mac companion restart.
            id: "com.microsoft.VSCode",
            appBundleIdentifier: "com.microsoft.VSCode",
            appName: "VS Code",
            rows: 3,
            columns: 5,
            keys: [
                DeckKey(
                    position: 0,
                    label: "Cmd Palette",
                    iconSystemName: "text.magnifyingglass",
                    action: .hotkey(key: "p", modifiers: [.command, .shift]),
                    role: .create
                ),
                DeckKey(
                    position: 1,
                    label: "Quick Open",
                    iconSystemName: "doc.text.magnifyingglass",
                    action: .hotkey(key: "p", modifiers: [.command]),
                    role: .create
                ),
                DeckKey(
                    position: 2,
                    label: "Toggle Term",
                    iconSystemName: "terminal",
                    action: .hotkey(key: "`", modifiers: [.control]),
                    role: .navigate
                ),
                DeckKey(
                    position: 3,
                    label: "Format Code",
                    iconSystemName: "wand.and.stars",
                    action: .hotkey(key: "f", modifiers: [.option, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 4,
                    label: "Source Control",
                    iconSystemName: "arrow.triangle.branch",
                    action: .hotkey(key: "g", modifiers: [.control, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 5,
                    label: "Run Tests",
                    iconSystemName: "play.circle.fill",
                    action: .hotkey(key: ";", modifiers: [.command]),
                    role: .run
                ),
                DeckKey(
                    position: 6,
                    label: "Sidebar",
                    iconSystemName: "sidebar.left",
                    action: .hotkey(key: "b", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 7,
                    label: "Find In Files",
                    iconSystemName: "magnifyingglass",
                    action: .hotkey(key: "f", modifiers: [.command, .shift]),
                    role: .navigate
                )
            ]
        )
    }

    public static func makeBrowserProfile(bundleId: String, name: String) -> DeckProfile {
        return DeckProfile(
            // Stable across launches so a pinned layout survives a Mac companion restart.
            id: bundleId,
            appBundleIdentifier: bundleId,
            appName: name,
            rows: 3,
            columns: 5,
            keys: [
                DeckKey(
                    position: 0,
                    label: "New Tab",
                    iconSystemName: "plus.circle.fill",
                    action: .hotkey(key: "t", modifiers: [.command]),
                    role: .create
                ),
                DeckKey(
                    position: 1,
                    label: "Close Tab",
                    iconSystemName: "xmark.circle.fill",
                    action: .hotkey(key: "w", modifiers: [.command]),
                    role: .danger
                ),
                DeckKey(
                    position: 2,
                    label: "Reopen Tab",
                    iconSystemName: "arrow.counterclockwise.circle.fill",
                    action: .hotkey(key: "t", modifiers: [.command, .shift]),
                    role: .create
                ),
                DeckKey(
                    position: 3,
                    label: "Dev Tools",
                    iconSystemName: "curlybraces",
                    action: .hotkey(key: "i", modifiers: [.command, .option]),
                    role: .navigate
                ),
                DeckKey(
                    position: 4,
                    label: "Reload",
                    iconSystemName: "arrow.clockwise",
                    action: .hotkey(key: "r", modifiers: [.command]),
                    role: .run
                )
            ]
        )
    }

    public static func makeTerminalProfile() -> DeckProfile {
        return DeckProfile(
            // Stable across launches so a pinned layout survives a Mac companion restart.
            id: "com.apple.Terminal",
            appBundleIdentifier: "com.apple.Terminal",
            appName: "Terminal",
            rows: 3,
            columns: 5,
            keys: [
                DeckKey(
                    position: 0,
                    label: "New Tab",
                    iconSystemName: "plus.square.on.square",
                    action: .hotkey(key: "t", modifiers: [.command]),
                    role: .create
                ),
                DeckKey(
                    position: 1,
                    label: "New Window",
                    iconSystemName: "macwindow.badge.plus",
                    action: .hotkey(key: "n", modifiers: [.command]),
                    role: .create
                ),
                DeckKey(
                    position: 2,
                    label: "Close Tab",
                    iconSystemName: "xmark.circle.fill",
                    action: .hotkey(key: "w", modifiers: [.command]),
                    role: .danger
                ),
                DeckKey(
                    position: 3,
                    label: "Prev Tab",
                    iconSystemName: "chevron.left.square",
                    action: .hotkey(key: "tab", modifiers: [.control, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 4,
                    label: "Next Tab",
                    iconSystemName: "chevron.right.square",
                    action: .hotkey(key: "tab", modifiers: [.control]),
                    role: .navigate
                ),
                DeckKey(
                    position: 5,
                    label: "Clear",
                    iconSystemName: "eraser",
                    action: .hotkey(key: "k", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 6,
                    label: "Interrupt",
                    iconSystemName: "stop.circle.fill",
                    action: .hotkey(key: "c", modifiers: [.control]),
                    role: .danger,
                    requiresConfirm: true
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
                    label: "Copy",
                    iconSystemName: "doc.on.doc",
                    action: .hotkey(key: "c", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 9,
                    label: "Paste",
                    iconSystemName: "doc.on.clipboard",
                    action: .hotkey(key: "v", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 10,
                    label: "Zoom In",
                    iconSystemName: "plus.magnifyingglass",
                    action: .hotkey(key: "=", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 11,
                    label: "Zoom Out",
                    iconSystemName: "minus.magnifyingglass",
                    action: .hotkey(key: "-", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 12,
                    label: "Split Pane",
                    iconSystemName: "rectangle.split.1x2",
                    action: .hotkey(key: "d", modifiers: [.command]),
                    role: .create
                ),
                DeckKey(
                    position: 13,
                    label: "Prev Cmd",
                    iconSystemName: "arrow.up.to.line",
                    action: .hotkey(key: "up", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 14,
                    label: "Next Cmd",
                    iconSystemName: "arrow.down.to.line",
                    action: .hotkey(key: "down", modifiers: [.command]),
                    role: .navigate
                )
            ]
        )
    }

    public static func makeXcodeProfile() -> DeckProfile {
        return DeckProfile(
            // Stable across launches so a pinned layout survives a Mac companion restart.
            id: "com.apple.dt.Xcode",
            appBundleIdentifier: "com.apple.dt.Xcode",
            appName: "Xcode",
            rows: 3,
            columns: 5,
            keys: [
                DeckKey(
                    position: 0,
                    label: "Run",
                    iconSystemName: "play.fill",
                    action: .hotkey(key: "r", modifiers: [.command]),
                    role: .run
                ),
                DeckKey(
                    position: 1,
                    label: "Build",
                    iconSystemName: "hammer.fill",
                    action: .hotkey(key: "b", modifiers: [.command]),
                    role: .run
                ),
                DeckKey(
                    position: 2,
                    label: "Test",
                    iconSystemName: "checkmark.diamond.fill",
                    action: .hotkey(key: "u", modifiers: [.command]),
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
                    label: "Clean",
                    iconSystemName: "trash",
                    action: .hotkey(key: "k", modifiers: [.command, .shift]),
                    role: .danger,
                    requiresConfirm: true
                ),
                DeckKey(
                    position: 5,
                    label: "Open Quickly",
                    iconSystemName: "doc.text.magnifyingglass",
                    action: .hotkey(key: "o", modifiers: [.command, .shift]),
                    role: .create
                ),
                DeckKey(
                    position: 6,
                    label: "Navigator",
                    iconSystemName: "sidebar.left",
                    action: .hotkey(key: "0", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 7,
                    label: "Debug Area",
                    iconSystemName: "rectangle.bottomthird.inset.filled",
                    action: .hotkey(key: "y", modifiers: [.command, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 8,
                    label: "Inspector",
                    iconSystemName: "sidebar.right",
                    action: .hotkey(key: "0", modifiers: [.command, .option]),
                    role: .navigate
                ),
                DeckKey(
                    position: 9,
                    label: "Canvas",
                    iconSystemName: "rectangle.righthalf.inset.filled",
                    action: .hotkey(key: "return", modifiers: [.command, .option]),
                    role: .modify
                ),
                DeckKey(
                    position: 10,
                    label: "Jump to Def",
                    iconSystemName: "arrow.right.circle",
                    action: .hotkey(key: "j", modifiers: [.command, .control]),
                    role: .navigate
                ),
                DeckKey(
                    position: 11,
                    label: "Back",
                    iconSystemName: "chevron.backward",
                    action: .hotkey(key: "left", modifiers: [.command, .control]),
                    role: .navigate
                ),
                DeckKey(
                    position: 12,
                    label: "Comment",
                    iconSystemName: "text.bubble",
                    action: .hotkey(key: "/", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 13,
                    label: "Re-Indent",
                    iconSystemName: "increase.indent",
                    action: .hotkey(key: "i", modifiers: [.control]),
                    role: .modify
                ),
                DeckKey(
                    position: 14,
                    label: "Find All",
                    iconSystemName: "magnifyingglass",
                    action: .hotkey(key: "f", modifiers: [.command, .shift]),
                    role: .navigate
                )
            ]
        )
    }

    /// Shortcuts taken from the WhatsApp for Mac menu bar (File, Chat, Call and View menus).
    public static func makeWhatsAppProfile() -> DeckProfile {
        return DeckProfile(
            // Stable across launches so a pinned layout survives a Mac companion restart.
            id: "net.whatsapp.WhatsApp",
            appBundleIdentifier: "net.whatsapp.WhatsApp",
            appName: "WhatsApp",
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
                    label: "New Group",
                    iconSystemName: "person.3.fill",
                    action: .hotkey(key: "n", modifiers: [.command, .shift]),
                    role: .create
                ),
                DeckKey(
                    position: 2,
                    label: "Search",
                    iconSystemName: "magnifyingglass",
                    action: .hotkey(key: "f", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 3,
                    label: "Search Chat",
                    iconSystemName: "text.magnifyingglass",
                    action: .hotkey(key: "f", modifiers: [.command, .option]),
                    role: .navigate
                ),
                DeckKey(
                    position: 4,
                    label: "Archived",
                    iconSystemName: "archivebox",
                    action: .hotkey(key: "4", modifiers: [.control]),
                    role: .navigate
                ),
                DeckKey(
                    position: 5,
                    label: "Prev Chat",
                    iconSystemName: "chevron.up",
                    action: .hotkey(key: "[", modifiers: [.command, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 6,
                    label: "Next Chat",
                    iconSystemName: "chevron.down",
                    action: .hotkey(key: "]", modifiers: [.command, .shift]),
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
                    label: "Archive",
                    iconSystemName: "archivebox.fill",
                    action: .hotkey(key: "e", modifiers: [.command, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 9,
                    label: "Pin",
                    iconSystemName: "pin.fill",
                    action: .hotkey(key: "p", modifiers: [.command, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 10,
                    label: "Mute Chat",
                    iconSystemName: "bell.slash.fill",
                    action: .hotkey(key: "m", modifiers: [.command, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 11,
                    label: "New Call",
                    iconSystemName: "phone.fill",
                    action: .hotkey(key: "c", modifiers: [.command, .shift]),
                    role: .run
                ),
                DeckKey(
                    position: 12,
                    label: "Mute Mic",
                    iconSystemName: "mic.slash.fill",
                    action: .hotkey(key: "m", modifiers: [.command, .control]),
                    role: .modify
                ),
                DeckKey(
                    position: 13,
                    label: "Camera Off",
                    iconSystemName: "video.slash.fill",
                    action: .hotkey(key: "v", modifiers: [.command, .control]),
                    role: .modify
                ),
                DeckKey(
                    position: 14,
                    label: "End Call",
                    iconSystemName: "phone.down.fill",
                    action: .hotkey(key: "w", modifiers: [.command, .control]),
                    role: .danger,
                    requiresConfirm: true
                )
            ]
        )
    }

    /// Default shortcuts of Telegram Desktop (``com.tdesktop.Telegram``), from
    /// ``Telegram/SourceFiles/core/shortcuts.cpp``. Qt maps "ctrl" to Command on macOS and
    /// "meta" to Control, so folder keys use Control while the rest use Command.
    public static func makeTelegramProfile() -> DeckProfile {
        return DeckProfile(
            // Stable across launches so a pinned layout survives a Mac companion restart.
            id: "com.tdesktop.Telegram",
            appBundleIdentifier: "com.tdesktop.Telegram",
            appName: "Telegram",
            rows: 3,
            columns: 5,
            keys: [
                DeckKey(
                    position: 0,
                    label: "Search",
                    iconSystemName: "magnifyingglass",
                    action: .hotkey(key: "f", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 1,
                    label: "Prev Chat",
                    iconSystemName: "chevron.up",
                    action: .hotkey(key: "up", modifiers: [.option]),
                    role: .navigate
                ),
                DeckKey(
                    position: 2,
                    label: "Next Chat",
                    iconSystemName: "chevron.down",
                    action: .hotkey(key: "down", modifiers: [.option]),
                    role: .navigate
                ),
                DeckKey(
                    position: 3,
                    label: "Saved Msgs",
                    iconSystemName: "bookmark.fill",
                    action: .hotkey(key: "0", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 4,
                    label: "Archive",
                    iconSystemName: "archivebox.fill",
                    action: .hotkey(key: "9", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 5,
                    label: "Pinned 1",
                    iconSystemName: "pin.fill",
                    action: .hotkey(key: "1", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 6,
                    label: "Pinned 2",
                    iconSystemName: "pin.fill",
                    action: .hotkey(key: "2", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 7,
                    label: "Pinned 3",
                    iconSystemName: "pin.fill",
                    action: .hotkey(key: "3", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 8,
                    label: "Pinned 4",
                    iconSystemName: "pin.fill",
                    action: .hotkey(key: "4", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 9,
                    label: "Contacts",
                    iconSystemName: "person.crop.circle",
                    action: .hotkey(key: "j", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 10,
                    label: "All Chats",
                    iconSystemName: "tray.full.fill",
                    action: .hotkey(key: "1", modifiers: [.control]),
                    role: .navigate
                ),
                DeckKey(
                    position: 11,
                    label: "Prev Folder",
                    iconSystemName: "folder",
                    action: .hotkey(key: "up", modifiers: [.control, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 12,
                    label: "Next Folder",
                    iconSystemName: "folder.fill",
                    action: .hotkey(key: "down", modifiers: [.control, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 13,
                    label: "Chat Menu",
                    iconSystemName: "ellipsis.circle",
                    action: .hotkey(key: "\\", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 14,
                    label: "Lock",
                    iconSystemName: "lock.fill",
                    action: .hotkey(key: "l", modifiers: [.command]),
                    role: .danger,
                    requiresConfirm: true
                )
            ]
        )
    }

    /// Zoom Workplace (``us.zoom.xos``). In-meeting shortcuts follow Zoom's published macOS hot
    /// keys (they only appear in the menu bar during a meeting); Join Meeting is from the app menu.
    public static func makeZoomProfile() -> DeckProfile {
        return DeckProfile(
            // Stable across launches so a pinned layout survives a Mac companion restart.
            id: "us.zoom.xos",
            appBundleIdentifier: "us.zoom.xos",
            appName: "Zoom",
            rows: 3,
            columns: 5,
            keys: [
                DeckKey(
                    position: 0,
                    label: "Mute",
                    iconSystemName: "mic.slash.fill",
                    action: .hotkey(key: "a", modifiers: [.command, .shift]),
                    role: .modify,
                    toggleChipId: "zoom.audio"
                ),
                DeckKey(
                    position: 1,
                    label: "Video",
                    iconSystemName: "video.fill",
                    action: .hotkey(key: "v", modifiers: [.command, .shift]),
                    role: .modify,
                    toggleChipId: "zoom.video"
                ),
                DeckKey(
                    position: 2,
                    label: "Share Screen",
                    iconSystemName: "rectangle.on.rectangle",
                    action: .hotkey(key: "s", modifiers: [.command, .shift]),
                    role: .run,
                    toggleChipId: "zoom.share"
                ),
                DeckKey(
                    position: 3,
                    label: "Pause Share",
                    iconSystemName: "pause.rectangle",
                    action: .hotkey(key: "t", modifiers: [.command, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 4,
                    label: "Raise Hand",
                    iconSystemName: "hand.raised.fill",
                    action: .hotkey(key: "y", modifiers: [.option]),
                    role: .modify
                ),
                DeckKey(
                    position: 5,
                    label: "Chat",
                    iconSystemName: "bubble.left.and.bubble.right.fill",
                    action: .hotkey(key: "h", modifiers: [.command, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 6,
                    label: "Participants",
                    iconSystemName: "person.2.fill",
                    action: .hotkey(key: "u", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 7,
                    label: "Switch View",
                    iconSystemName: "square.grid.2x2",
                    action: .hotkey(key: "w", modifiers: [.command, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 8,
                    label: "Mini Window",
                    iconSystemName: "pip",
                    action: .hotkey(key: "m", modifiers: [.command, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 9,
                    label: "Full Screen",
                    iconSystemName: "arrow.up.left.and.arrow.down.right",
                    action: .hotkey(key: "f", modifiers: [.command, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 10,
                    label: "Invite",
                    iconSystemName: "person.badge.plus",
                    action: .hotkey(key: "i", modifiers: [.command]),
                    role: .create
                ),
                DeckKey(
                    position: 11,
                    label: "Record",
                    iconSystemName: "record.circle",
                    action: .hotkey(key: "r", modifiers: [.command, .shift]),
                    role: .run,
                    toggleChipId: "zoom.recording"
                ),
                DeckKey(
                    position: 12,
                    label: "Pause Rec",
                    iconSystemName: "pause.circle",
                    action: .hotkey(key: "p", modifiers: [.command, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 13,
                    label: "Switch Camera",
                    iconSystemName: "arrow.triangle.2.circlepath.camera",
                    action: .hotkey(key: "n", modifiers: [.command, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 14,
                    label: "Join Meeting",
                    iconSystemName: "plus.circle.fill",
                    action: .hotkey(key: "j", modifiers: [.command]),
                    role: .run
                )
            ]
        )
    }

    /// Shortcuts taken from the MacDown menu bar (File, View and Format menus).
    public static func makeMacDownProfile() -> DeckProfile {
        return DeckProfile(
            // Stable across launches so a pinned layout survives a Mac companion restart.
            id: "com.uranusjr.macdown",
            appBundleIdentifier: "com.uranusjr.macdown",
            appName: "MacDown",
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
                    label: "Open",
                    iconSystemName: "folder",
                    action: .hotkey(key: "o", modifiers: [.command]),
                    role: .create
                ),
                DeckKey(
                    position: 2,
                    label: "Save",
                    iconSystemName: "square.and.arrow.down",
                    action: .hotkey(key: "s", modifiers: [.command]),
                    role: .run
                ),
                DeckKey(
                    position: 3,
                    label: "Copy HTML",
                    iconSystemName: "chevron.left.forwardslash.chevron.right",
                    action: .hotkey(key: "c", modifiers: [.command, .option]),
                    role: .create
                ),
                DeckKey(
                    position: 4,
                    label: "1:1 Split",
                    iconSystemName: "rectangle.split.2x1",
                    action: .hotkey(key: "0", modifiers: [.command, .shift]),
                    role: .navigate
                ),
                DeckKey(
                    position: 5,
                    label: "Bold",
                    iconSystemName: "bold",
                    action: .hotkey(key: "b", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 6,
                    label: "Italic",
                    iconSystemName: "italic",
                    action: .hotkey(key: "i", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 7,
                    label: "Code",
                    iconSystemName: "curlybraces",
                    action: .hotkey(key: "k", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 8,
                    label: "Link",
                    iconSystemName: "link",
                    action: .hotkey(key: "k", modifiers: [.command, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 9,
                    label: "Image",
                    iconSystemName: "photo",
                    action: .hotkey(key: "i", modifiers: [.command, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 10,
                    label: "Numbered",
                    iconSystemName: "list.number",
                    action: .hotkey(key: "o", modifiers: [.command, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 11,
                    label: "Bullets",
                    iconSystemName: "list.bullet",
                    action: .hotkey(key: "u", modifiers: [.command, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 12,
                    label: "Quote",
                    iconSystemName: "text.quote",
                    action: .hotkey(key: "b", modifiers: [.command, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 13,
                    label: "Comment",
                    iconSystemName: "text.bubble",
                    action: .hotkey(key: "/", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 14,
                    label: "Indent",
                    iconSystemName: "increase.indent",
                    action: .hotkey(key: "]", modifiers: [.command]),
                    role: .modify
                )
            ]
        )
    }

    /// Microsoft Word (``com.microsoft.Word``). New, Open, Save, Print, Undo, Redo, Link and Focus
    /// come from Word's menu bar; formatting, Comment and Track Changes from Microsoft's published
    /// "Keyboard shortcuts in Word" (macOS).
    public static func makeWordProfile() -> DeckProfile {
        return DeckProfile(
            // Stable across launches so a pinned layout survives a Mac companion restart.
            id: "com.microsoft.Word",
            appBundleIdentifier: "com.microsoft.Word",
            appName: "Word",
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
                    label: "Open",
                    iconSystemName: "folder",
                    action: .hotkey(key: "o", modifiers: [.command]),
                    role: .create
                ),
                DeckKey(
                    position: 2,
                    label: "Save",
                    iconSystemName: "square.and.arrow.down",
                    action: .hotkey(key: "s", modifiers: [.command]),
                    role: .run
                ),
                DeckKey(
                    position: 3,
                    label: "Print",
                    iconSystemName: "printer",
                    action: .hotkey(key: "p", modifiers: [.command]),
                    role: .run
                ),
                DeckKey(
                    position: 4,
                    label: "Find",
                    iconSystemName: "magnifyingglass",
                    action: .hotkey(key: "f", modifiers: [.command]),
                    role: .navigate
                ),
                DeckKey(
                    position: 5,
                    label: "Bold",
                    iconSystemName: "bold",
                    action: .hotkey(key: "b", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 6,
                    label: "Italic",
                    iconSystemName: "italic",
                    action: .hotkey(key: "i", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 7,
                    label: "Underline",
                    iconSystemName: "underline",
                    action: .hotkey(key: "u", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 8,
                    label: "Link",
                    iconSystemName: "link",
                    action: .hotkey(key: "k", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 9,
                    label: "Center",
                    iconSystemName: "text.aligncenter",
                    action: .hotkey(key: "e", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 10,
                    label: "Comment",
                    iconSystemName: "text.bubble",
                    action: .hotkey(key: "a", modifiers: [.command, .option]),
                    role: .create
                ),
                DeckKey(
                    position: 11,
                    label: "Track Changes",
                    iconSystemName: "pencil.line",
                    action: .hotkey(key: "e", modifiers: [.command, .shift]),
                    role: .modify
                ),
                DeckKey(
                    position: 12,
                    label: "Undo",
                    iconSystemName: "arrow.uturn.backward",
                    action: .hotkey(key: "z", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 13,
                    label: "Redo",
                    iconSystemName: "arrow.uturn.forward",
                    action: .hotkey(key: "y", modifiers: [.command]),
                    role: .modify
                ),
                DeckKey(
                    position: 14,
                    label: "Focus",
                    iconSystemName: "eye",
                    action: .hotkey(key: "f", modifiers: [.command, .shift, .control]),
                    role: .navigate
                )
            ]
        )
    }

    public static func allDefaultProfiles() -> [DeckProfile] {
        return [
            makeDefaultFallbackProfile(),
            makeVSCodeProfile(),
            makeTerminalProfile(),
            makeXcodeProfile(),
            makeWhatsAppProfile(),
            makeTelegramProfile(),
            makeZoomProfile(),
            makeMacDownProfile(),
            makeWordProfile(),
            makeBrowserProfile(bundleId: "com.apple.Safari", name: "Safari"),
            makeBrowserProfile(bundleId: "com.google.Chrome", name: "Google Chrome"),
            makeBrowserProfile(bundleId: "company.thebrowser.Browser", name: "Arc")
        ]
    }
}
