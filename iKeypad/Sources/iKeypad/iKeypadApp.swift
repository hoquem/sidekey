import SwiftUI
import iKeypadShared
import UIKit

@main
struct iKeypadApp: App {
    @StateObject private var client = DeckClient.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(client)
                // The deck is a dark hardware surface whatever the system appearance.
                .preferredColorScheme(.dark)
                .onAppear {
                    client.startDiscovery()
                }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var client: DeckClient
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height * 1.15
            let margin: CGFloat = 24

            ZStack(alignment: .bottom) {
                DeckTheme.plate.ignoresSafeArea()

                if isLandscape {
                    HStack(alignment: .top, spacing: 28) {
                        NowControllingView(isColumn: true)
                            .frame(width: min(300, geo.size.width * 0.28))
                            .frame(maxHeight: .infinity, alignment: .topLeading)
                        keyGrid(portrait: false)
                    }
                    .padding(margin)
                } else {
                    VStack(spacing: 24) {
                        NowControllingView(isColumn: false)
                        keyGrid(portrait: true)
                    }
                    .padding(margin)
                }

                if let toast = client.toast {
                    ToastView(toast: toast)
                        .padding(.bottom, 28)
                        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeOut(duration: 0.25), value: client.toast)
        }
        .onChange(of: client.displayedProfile.id) { _ in
            // Announce rather than move VoiceOver focus: the Mac's focus changes constantly.
            UIAccessibility.post(notification: .announcement, argument: "Now controlling \(client.displayedProfile.appName)")
        }
    }

    /// The key grid. Profiles are authored as rows x columns in reading order; portrait turns the
    /// grid on its side (columns become rows) so keys fill the tall screen, keeping reading order.
    private func keyGrid(portrait: Bool) -> some View {
        GeometryReader { geo in
            let profile = client.displayedProfile
            let rows = max(portrait ? profile.columns : profile.rows, 1)
            let columns = max(portrait ? profile.rows : profile.columns, 1)
            let gap = min(geo.size.width, geo.size.height) * 0.028
            let width = max(0, (geo.size.width - gap * CGFloat(columns - 1)) / CGFloat(columns))
            let height = max(0, (geo.size.height - gap * CGFloat(rows - 1)) / CGFloat(rows))
            // Keys stay close to square: at most 1.1x (portrait) or 1.25x (landscape) taller than wide.
            let size = CGSize(width: min(width, height * 1.4), height: min(height, width * (portrait ? 1.1 : 1.25)))
            // Height the clamp leaves over goes into the row gaps (up to 2.5x), so the grid still spans the screen.
            let rowGap = rows > 1
                ? min(max(gap, (geo.size.height - size.height * CGFloat(rows)) / CGFloat(rows - 1)), gap * 2.5)
                : gap
            let keysBySlot = Dictionary(profile.keys.map { ($0.position, $0) }, uniquingKeysWith: { first, _ in first })
            let chips = Dictionary((client.appContext?.chips ?? []).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            let appName = profile.appBundleIdentifier == "default" ? (client.appContext?.appName ?? "your Mac") : profile.appName

            VStack(spacing: rowGap) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: gap) {
                        ForEach(0..<columns, id: \.self) { column in
                            if let key = keysBySlot[row * columns + column] {
                                DeckKeyView(
                                    key: key,
                                    appName: appName,
                                    size: size,
                                    feedback: client.keyFeedback[key.id],
                                    liveChip: key.toggleChipId.flatMap { chips[$0] },
                                    isEnabled: client.isConnected,
                                    onFire: { client.triggerKey(key) },
                                    onHoldHint: { client.showToast("Hold to \(key.label.lowercased()).", isError: false) }
                                )
                            } else {
                                EmptyKeyWell(size: size)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: portrait ? .top : .center)
            .id(profile.id)
            .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.985)))
            .animation(.easeOut(duration: 0.22), value: profile.id)
        }
    }
}

/// A short message pinned to the bottom of the deck.
struct ToastView: View {
    let toast: DeckToast

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: toast.isError ? "exclamationmark.triangle.fill" : "hand.tap.fill")
                .foregroundStyle(toast.isError ? DeckTheme.failure : DeckTheme.lit)
            Text(toast.message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(DeckTheme.label)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(DeckTheme.raised)
                .shadow(color: .black.opacity(0.5), radius: 16, x: 0, y: 8)
        )
        .padding(.horizontal, 24)
        .accessibilityElement(children: .combine)
    }
}
