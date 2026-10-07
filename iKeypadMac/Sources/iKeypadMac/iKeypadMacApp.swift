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

                Button("Quit Sidekey") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
            .padding(4)
        }
    }
}
