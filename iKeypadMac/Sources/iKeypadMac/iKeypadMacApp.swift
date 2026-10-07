import SwiftUI
import iKeypadShared

@main
struct iKeypadMacApp: App {
    @StateObject private var contextMonitor = AppContextMonitor.shared
    @StateObject private var server = DeckServer.shared

    init() {
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
                    Text("Connected iPads:")
                        .foregroundColor(.secondary)
                    Text("\(server.connectedClientsCount)")
                        .bold()
                }

                Divider()

                PairingMenuSection(server: server, pairing: server.pairing)

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
            Button("Pair iPad...") {
                server.openPairing()
                showCode()
            }
        }
        if server.pairedDeviceCount > 0 {
            Button("Forget Paired iPads (\(server.pairedDeviceCount))") { server.forgetPairedDevices() }
        }
    }

    private func showCode() {
        PairingCodeWindow.shared.show(for: pairing) { [pairing] in pairing.close() }
    }
}
