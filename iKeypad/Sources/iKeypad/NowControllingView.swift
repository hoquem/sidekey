import SwiftUI
import iKeypadShared

/// The band that says which Mac app the deck is driving: its icon, name, focused window, live
/// state chips, and the link to the Mac. While not connected it explains what is happening.
struct NowControllingView: View {
    @EnvironmentObject private var client: DeckClient
    /// ``true`` in landscape, where the band becomes a column beside the grid.
    let isColumn: Bool

    private static let setupHintDelay: TimeInterval = 8

    var body: some View {
        Group {
            if client.isConnected {
                connected
            } else if case .pairing(let error) = client.phase {
                PairingPrompt(hostName: client.hostName, error: error, isColumn: isColumn)
            } else {
                notConnected
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Connected

    @ViewBuilder private var connected: some View {
        if isColumn {
            VStack(alignment: .leading, spacing: 16) {
                appIcon(size: 72)
                identity(nameFont: .title.weight(.bold), titleLines: 3)
                chips(vertical: true)
                Spacer(minLength: 0)
                linkAndPin
            }
        } else {
            HStack(alignment: .center, spacing: 18) {
                appIcon(size: 64)
                VStack(alignment: .leading, spacing: 8) {
                    identity(nameFont: .title2.weight(.bold), titleLines: 1)
                    chips(vertical: false)
                }
                Spacer(minLength: 12)
                linkAndPin
            }
        }
    }

    private var pinned: DeckProfile? { client.pinnedProfile }

    private var appName: String {
        pinned?.appName ?? client.appContext?.appName ?? client.currentProfile.appName
    }

    private var windowTitle: String? {
        if let pinned { return "Pinned. Keys bring \(pinned.appName) forward." }
        return client.appContext?.windowTitle
    }

    private func appIcon(size: CGFloat) -> some View {
        let image = pinned.flatMap { client.cachedIcon(for: $0.appBundleIdentifier) } ?? client.appIcon
        return Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .fill(DeckTheme.raised)
                    .overlay(
                        Image(systemName: "macwindow")
                            .font(.system(size: size * 0.4, weight: .medium))
                            .foregroundStyle(DeckTheme.secondaryLabel)
                    )
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func identity(nameFont: Font, titleLines: Int) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(appName)
                .font(nameFont)
                .foregroundStyle(DeckTheme.label)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let windowTitle {
                Text(windowTitle)
                    .font(.subheadline)
                    .foregroundStyle(DeckTheme.secondaryLabel)
                    .lineLimit(titleLines)
                    .truncationMode(.middle)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Now controlling \(appName)" + (windowTitle.map { ", \($0)" } ?? ""))
    }

    /// State chips: missing permission first, then the app's own, then a note when the app has
    /// no layout of its own.
    private var chipList: [ContextChip] {
        var list: [ContextChip] = []
        if client.appContext?.accessibilityTrusted == false {
            list.append(ContextChip(id: "mac.accessibility", label: "Mac needs Accessibility permission",
                                    systemImage: "exclamationmark.triangle.fill", tone: .bad, isOn: nil))
        }
        if pinned == nil {
            list += client.appContext?.chips ?? []
            if client.currentProfile.appBundleIdentifier == "default" {
                list.append(ContextChip(id: "deck.fallback", label: "System keys", systemImage: "square.grid.3x3",
                                        tone: .neutral, isOn: nil))
            }
        }
        return list
    }

    @ViewBuilder private func chips(vertical: Bool) -> some View {
        let list = chipList
        if !list.isEmpty {
            let layout = vertical ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8)) : AnyLayout(HStackLayout(spacing: 8))
            layout {
                ForEach(list) { chip in ChipView(chip: chip) }
            }
        }
    }

    private var linkAndPin: some View {
        HStack(spacing: 12) {
            VStack(alignment: isColumn ? .leading : .trailing, spacing: 2) {
                Label(client.isUSB ? "USB" : "Wi-Fi", systemImage: client.isUSB ? "cable.connector" : "wifi")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(DeckTheme.label)
                if let host = client.hostName {
                    Text(host)
                        .font(.caption)
                        .foregroundStyle(DeckTheme.secondaryLabel)
                        .lineLimit(1)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Connected to \(client.hostName ?? "your Mac") over \(client.isUSB ? "USB" : "Wi-Fi")")
            .contextMenu {
                Button(role: .destructive) { client.forgetPairedMac() } label: {
                    Label("Forget This Mac", systemImage: "link.badge.plus")
                }
            }

            Button {
                client.togglePin()
            } label: {
                Image(systemName: pinned == nil ? "pin" : "pin.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(pinned == nil ? DeckTheme.secondaryLabel : DeckTheme.lit)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(pinned == nil ? DeckTheme.raised : DeckTheme.lit.opacity(0.16)))
            }
            .accessibilityLabel(pinned == nil ? "Pin these keys" : "Unpin keys")
            .accessibilityHint(pinned == nil ? "Keeps this layout on screen when you switch apps on your Mac." : "Keys follow your Mac's frontmost app again.")
        }
    }

    // MARK: - Not connected

    private var notConnected: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    ProgressView()
                        .tint(DeckTheme.secondaryLabel)
                    Text(headline)
                        .font(isColumn ? .title2.weight(.bold) : .title3.weight(.bold))
                        .foregroundStyle(DeckTheme.label)
                }
                if let help = help(at: timeline.date) {
                    Text(help)
                        .font(.subheadline)
                        .foregroundStyle(DeckTheme.secondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var headline: String {
        switch client.phase {
        case .reconnecting: return "Reconnecting to \(client.hostName ?? "your Mac")…"
        case .connecting: return "Connecting…"
        case .searching, .connected, .pairing: return "Looking for \(client.pairedMacName ?? "your Mac")…"
        }
    }

    private func help(at now: Date) -> String? {
        switch client.phase {
        case .searching(let since) where now.timeIntervalSince(since) >= Self.setupHintDelay:
            return "Open Sidekey on your Mac, then connect this iPad with a USB cable or join the same Wi-Fi network."
        case .reconnecting:
            return "Keys are paused until the Mac is back."
        default:
            return nil
        }
    }
}

/// A small capsule of app state, such as "Muted" or "Recording".
struct ChipView: View {
    let chip: ContextChip

    var body: some View {
        let color = DeckTheme.tone(chip.tone)
        Label(chip.label, systemImage: chip.systemImage)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(color.opacity(0.14)))
    }
}

/// Asks for the 6-digit code the Mac shows under Pair iPad in its Sidekey menu.
private struct PairingPrompt: View {
    @EnvironmentObject private var client: DeckClient
    let hostName: String?
    let error: String?
    let isColumn: Bool
    @State private var code = ""
    @FocusState private var focused: Bool

    private var isComplete: Bool { code.filter(\.isNumber).count == 6 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pair with \(hostName ?? "your Mac")")
                .font(isColumn ? .title2.weight(.bold) : .title3.weight(.bold))
                .foregroundStyle(DeckTheme.label)
            Text("On your Mac, open the Sidekey menu and choose Pair iPad. Enter the code it shows.")
                .font(.subheadline)
                .foregroundStyle(DeckTheme.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 12) {
                TextField("6-digit code", text: $code)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .font(.title3.monospacedDigit().weight(.semibold))
                    .foregroundStyle(DeckTheme.label)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 48)
                    .frame(maxWidth: 220)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(DeckTheme.well))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(DeckTheme.hairline))
                    .focused($focused)
                    .accessibilityLabel("Pairing code")
                    .onSubmit(submit)
                Button("Pair", action: submit)
                    .font(.body.weight(.semibold))
                    .frame(minWidth: 88, minHeight: 48)
                    .foregroundStyle(isComplete ? DeckTheme.label : DeckTheme.secondaryLabel)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(DeckTheme.raised))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(isComplete ? DeckTheme.lit : DeckTheme.hairline, lineWidth: isComplete ? 2 : 1))
                    .disabled(!isComplete)
            }
            if let error {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundStyle(DeckTheme.failure)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onAppear { focused = true }
    }

    private func submit() {
        guard isComplete else { return }
        client.submitPairingCode(code)
        code = ""
    }
}
