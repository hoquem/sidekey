import SwiftUI
import iKeypadShared

@main
struct iKeypadMacApp: App {
    @StateObject private var contextMonitor = AppContextMonitor.shared
    @StateObject private var server = DeckServer.shared

    init() {
        DeckServer.shared.start()
    }

    var body: some Scene {
        MenuBarExtra("iKeypad", systemImage: "keyboard.badge.ellipsis") {
            VStack(alignment: .leading, spacing: 6) {
                Text("iKeypad Companion")
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

                Button("Open Settings...") {
                    // Open preferences window
                }

                Button("Quit iKeypad") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
            .padding(4)
        }
    }
}
