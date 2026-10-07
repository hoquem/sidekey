import Cocoa
import ApplicationServices
import iKeypadShared

/// Reads live state of a running Mac app for the iPad's Now Controlling band.
///
/// Window titles and Zoom meeting state come from the Accessibility API, so they are only
/// available once the companion is trusted under System Settings › Privacy & Security ›
/// Accessibility. Without that trust every reader returns ``nil`` / no chips.
enum AppStateReader {
    static var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Show macOS's Accessibility prompt if Sidekey isn't trusted yet; this also adds Sidekey
    /// to the list in System Settings so the user only has to switch it on.
    static func requestAccessibilityIfNeeded() {
        guard !isAccessibilityTrusted else { return }
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    /// Title of the app's focused window, or ``nil`` when unavailable.
    static func focusedWindowTitle(of app: NSRunningApplication) -> String? {
        let element = AXUIElementCreateApplication(app.processIdentifier)
        guard let window = copyAttribute(element, kAXFocusedWindowAttribute) else { return nil }
        // AXUIElement is a CF type; the attribute value for a window is always an AXUIElement.
        let title = copyAttribute(window as! AXUIElement, kAXTitleAttribute) as? String
        return title.flatMap { $0.isEmpty ? nil : $0 }
    }

    /// PNG of the app's icon at ``pointSize`` (rendered at 2x).
    ///
    /// :param app: The running application.
    /// :param pointSize: Edge length in points; the PNG is twice this in pixels.
    /// :returns: PNG data, or ``nil`` when the app has no bundle URL.
    static func iconPNG(of app: NSRunningApplication, pointSize: CGFloat = 64) -> Data? {
        guard let url = app.bundleURL else { return nil }
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        let pixels = Int(pointSize * 2)
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        ) else { return nil }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        icon.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
        NSGraphicsContext.restoreGraphicsState()
        return rep.representation(using: .png, properties: [:])
    }

    /// Context chips for apps that expose useful state; empty for the rest.
    static func chips(for app: NSRunningApplication) -> [ContextChip] {
        switch app.bundleIdentifier {
        case "us.zoom.xos":
            return zoomChips(for: app)
        default:
            return []
        }
    }

    // MARK: - Zoom

    /// Zoom meeting state, read from the titles of Zoom's in-meeting menu items, which flip
    /// between e.g. "Mute Audio" and "Unmute Audio". Outside a meeting those items are absent.
    ///
    /// The titles below follow Zoom's documented menu wording; verify them in a live meeting.
    private static func zoomChips(for app: NSRunningApplication) -> [ContextChip] {
        let titles = menuItemTitles(of: app)
        guard !titles.isEmpty else { return [] }

        func has(_ candidates: [String]) -> Bool {
            candidates.contains { titles.contains($0) }
        }

        var chips: [ContextChip] = []
        if has(["Unmute Audio", "Unmute My Audio"]) {
            chips.append(ContextChip(id: "zoom.audio", label: "Muted", systemImage: "mic.slash.fill", tone: .bad, isOn: false))
        } else if has(["Mute Audio", "Mute My Audio"]) {
            chips.append(ContextChip(id: "zoom.audio", label: "Mic live", systemImage: "mic.fill", tone: .good, isOn: true))
        }
        if has(["Start Video", "Start My Video"]) {
            chips.append(ContextChip(id: "zoom.video", label: "Camera off", systemImage: "video.slash.fill", tone: .neutral, isOn: false))
        } else if has(["Stop Video", "Stop My Video"]) {
            chips.append(ContextChip(id: "zoom.video", label: "Camera on", systemImage: "video.fill", tone: .good, isOn: true))
        }
        if has(["Stop Share", "Stop Sharing", "Stop Screen Sharing"]) {
            chips.append(ContextChip(id: "zoom.share", label: "Sharing", systemImage: "rectangle.on.rectangle", tone: .warn, isOn: true))
        }
        if has(["Stop Recording", "Pause Recording", "Pause/Stop Recording"]) {
            chips.append(ContextChip(id: "zoom.recording", label: "Recording", systemImage: "record.circle", tone: .bad, isOn: true))
        }
        if chips.isEmpty {
            chips.append(ContextChip(id: "zoom.meeting", label: "Not in a meeting", systemImage: "video.badge.ellipsis", tone: .neutral, isOn: nil))
        }
        return chips
    }

    /// Titles of every item in the app's menu bar menus, one level deep.
    private static func menuItemTitles(of app: NSRunningApplication) -> Set<String> {
        let element = AXUIElementCreateApplication(app.processIdentifier)
        guard let menuBar = copyAttribute(element, kAXMenuBarAttribute) else { return [] }
        var titles = Set<String>()
        for barItem in children(of: menuBar as! AXUIElement) {
            for menu in children(of: barItem) {
                for item in children(of: menu) {
                    if let title = copyAttribute(item, kAXTitleAttribute) as? String, !title.isEmpty {
                        titles.insert(title)
                    }
                }
            }
        }
        return titles
    }

    // MARK: - AX helpers

    private static func copyAttribute(_ element: AXUIElement, _ attribute: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else { return nil }
        return value
    }

    private static func children(of element: AXUIElement) -> [AXUIElement] {
        (copyAttribute(element, kAXChildrenAttribute) as? [AXUIElement]) ?? []
    }
}
