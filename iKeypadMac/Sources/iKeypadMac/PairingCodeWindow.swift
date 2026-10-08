import AppKit
import Combine
import SwiftUI

/// Shows the pairing code in its own window, large enough to read across a desk, and closes it
/// when pairing finishes or the code expires.
@MainActor
final class PairingCodeWindow {
    static let shared = PairingCodeWindow()

    private var window: NSWindow?
    private var observation: AnyCancellable?

    func show(for pairing: PairingWindow, onStop: @escaping () -> Void) {
        if window == nil {
            let hosting = NSHostingController(rootView: PairingCodeView(pairing: pairing, onStop: onStop))
            let window = NSWindow(contentViewController: hosting)
            window.title = "Pair Device"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.level = .floating
            window.center()
            self.window = window
        }
        observation = pairing.$code
            .receive(on: RunLoop.main)
            .sink { [weak self] code in
                if code == nil { self?.window?.close() }
            }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}

private struct PairingCodeView: View {
    @ObservedObject var pairing: PairingWindow
    let onStop: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Text("Enter this code on your iPad")
                .font(.title3.weight(.semibold))
            if let code = pairing.code {
                Text("\(String(code.prefix(3))) \(String(code.suffix(3)))")
                    .font(.system(size: 64, weight: .bold, design: .monospaced))
                    .kerning(4)
                    .textSelection(.enabled)
                    .accessibilityLabel("Pairing code \(code.map(String.init).joined(separator: " "))")
            }
            if let expiresAt = pairing.expiresAt {
                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    let remaining = max(0, Int(expiresAt.timeIntervalSince(timeline.date)))
                    Text("Expires in \(remaining / 60):\(String(format: "%02d", remaining % 60))")
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            Text("In Sidekey on the iPad, type the code and tap Pair.")
                .font(.callout)
                .foregroundStyle(.secondary)
            Button("Stop Pairing", action: onStop)
                .keyboardShortcut(.cancelAction)
        }
        .padding(32)
        .frame(minWidth: 380)
    }
}
