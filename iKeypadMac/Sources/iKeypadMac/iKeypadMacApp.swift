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
private struct PairingMenuSection: View {
    @ObservedObject var server: DeckServer
    @ObservedObject var pairing: PairingWindow

    var body: some View {
        if let code = pairing.code, let expiresAt = pairing.expiresAt {
            TimelineView(.periodic(from: .now, by: 1)) { timeline in
                let remaining = max(0, Int(expiresAt.timeIntervalSince(timeline.date)))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pairing code")
                        .foregroundColor(.secondary)
                    Text(code.prefix(3) + " " + code.suffix(3))
                        .font(.system(.title, design: .monospaced).weight(.semibold))
                    Text(remaining > 0 ? "Enter it on your iPad within \(remaining) s" : "Code expired")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Button("Stop Pairing") { pairing.close() }
        } else {
            Button("Pair iPad...") { server.openPairing() }
        }
        if server.pairedDeviceCount > 0 {
            Button("Forget Paired iPads (\(server.pairedDeviceCount))") { server.forgetPairedDevices() }
        }
    }
}
