import SwiftUI
import iKeypadShared

@main
struct iKeypadMacApp: App {
    @StateObject private var contextMonitor = AppContextMonitor.shared
    @StateObject private var server = DeckServer.shared

    init() {
        // Before the server starts, so the first layout an iPad receives already has the user's keys.
        AppContextMonitor.shared.reloadUserLayouts(from: .app)
        DeckServer.shared.start()
        // Keys can't fire without Accessibility; ask macOS to prompt (and list Sidekey in
        // System Settings) rather than failing silently on the first tap.
        AppStateReader.requestAccessibilityIfNeeded()
    }

    var body: some Scene {
        MenuBarExtra("Sidekey", systemImage: "keyboard.badge.ellipsis") {
            VStack(alignment: .leading, spacing: 6) {
                Text("Sidekey")
                    .font(.headline)

                Divider()

                HStack {
                    Text("Active App:")
                        .foregroundColor(.secondary)
                    Text(contextMonitor.activeAppName)
                        .fontWeight(.medium)
                }

                HStack {
                    Text("Profile:")
                        .foregroundColor(.secondary)
                    Text(contextMonitor.activeProfile.appName)
                }

                HStack {
                    Text("Connected devices:")
                        .foregroundColor(.secondary)
                    Text("\(server.connectedClientsCount)")
                        .bold()
                }

                Divider()

                PairingMenuSection(server: server, pairing: server.pairing)

                Divider()

                LayoutsMenuSection(monitor: contextMonitor)

                Divider()

                Button("Quit Sidekey") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
            .padding(4)
        }
    }
}

/// Pairing controls in the menu: open a short-lived code for a new iPad, or forget paired iPads.
///
/// The menu bar extra renders as a native menu, so nothing here may update on a timer: a
/// once-a-second countdown rebuilt the menu recursively and crashed the app. The code and its
/// countdown live in ``PairingCodeWindow`` instead.
private struct PairingMenuSection: View {
    @ObservedObject var server: DeckServer
    @ObservedObject var pairing: PairingWindow

    var body: some View {
        if pairing.isOpen {
            Button("Show Pairing Code...") { showCode() }
            Button("Stop Pairing") { pairing.close() }
        } else {
            Button("Pair Device...") {
                server.openPairing()
                showCode()
            }
        }
        if server.pairedDeviceCount > 0 {
            Button("Forget Paired Devices (\(server.pairedDeviceCount))") { server.forgetPairedDevices() }
        }
    }

    private func showCode() {
        PairingCodeWindow.shared.show(for: pairing) { [pairing] in pairing.close() }
    }
}

/// Reload hand-edited layout files, and say when any were refused. The error count changes only
/// on reload, from a menu action, never while the menu is open (see ``PairingMenuSection``).
private struct LayoutsMenuSection: View {
    @ObservedObject var monitor: AppContextMonitor

    var body: some View {
        Button("Edit Layouts...") { LayoutEditorWindow.shared.show() }
        Button("Reload Layouts") { monitor.reloadUserLayouts(from: .app) }
        if !monitor.layoutFileErrors.isEmpty {
            let count = monitor.layoutFileErrors.count
            Button("\(count) layout file\(count == 1 ? " has" : "s have") errors...") {
                showErrors(monitor.layoutFileErrors)
            }
        }
    }

    private func showErrors(_ errors: [LayoutFileError]) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Sidekey didn't load these layout files"
        alert.informativeText = errors.map { "\($0.fileName): \($0.reason)" }.joined(separator: "\n\n")
            + "\n\nSidekey is using the built-in layouts for these apps. Files are in \(UserLayoutStore.defaultDirectory.path)."
        alert.runModal()
    }
}
