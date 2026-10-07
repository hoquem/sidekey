import SwiftUI
import iKeypadShared
import UIKit

/// One keycap on the deck.
///
/// The cap shows the key's icon (tinted by role), its label, and the shortcut it sends. It
/// reflects the Mac's answer: a lit amber edge when the key fired, a red edge and shake when it
/// failed. Disruptive keys fire only after a press-and-hold that fills the cap.
struct DeckKeyView: View {
    let key: DeckKey
    let appName: String
    let size: CGSize
    let feedback: KeyFeedback?
    /// Live state from the app, for keys bound to a context chip (e.g. Zoom's mic).
    let liveChip: ContextChip?
    let isEnabled: Bool
    let onFire: () -> Void
    let onHoldHint: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var holdProgress: CGFloat = 0
    @State private var isHolding = false
    @State private var holdStart: Date?
    @State private var holdFired = false
    @State private var shakes: CGFloat = 0

    private static let holdDuration: TimeInterval = 0.6
    /// The shorter edge; type, icon and corner radius scale from it.
    private var side: CGFloat { min(size.width, size.height) }
    private var corner: CGFloat { side * 0.16 }
    private var tint: Color { DeckTheme.tint(for: key.role) }
    /// A bound chip in an attention state (muted, sharing, recording) lights the key.
    private var isLitByState: Bool {
        guard let liveChip else { return false }
        return liveChip.tone == .bad || liveChip.tone == .warn
    }

    var body: some View {
        Group {
            if key.requiresConfirm {
                cap(pressed: isHolding)
                    .gesture(holdGesture)
            } else {
                Button(action: fire) { EmptyView() }
                    .buttonStyle(CapButtonStyle { pressed in AnyView(cap(pressed: pressed)) })
            }
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.38)
        .modifier(ShakeEffect(animatableData: shakes))
        .onChange(of: feedback) { newValue in
            if case .failed = newValue, !reduceMotion {
                withAnimation(.linear(duration: 0.36)) { shakes += 1 }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        // VoiceOver's double-tap is already deliberate, so it fires without the hold.
        .accessibilityAction { onFire() }
        .accessibilityLabel(key.label)
        .accessibilityValue(liveChip?.label ?? "")
        .accessibilityHint(accessibilityHint)
    }

    // MARK: - Cap

    private func cap(pressed: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)
        return ZStack {
            shape.fill(
                pressed
                    ? AnyShapeStyle(DeckTheme.capPressed)
                    : AnyShapeStyle(LinearGradient(colors: [DeckTheme.capTop, DeckTheme.capBottom], startPoint: .top, endPoint: .bottom))
            )

            if key.requiresConfirm {
                // Hold-to-fire fill rises from the bottom of the cap.
                GeometryReader { geo in
                    Rectangle()
                        .fill(tint.opacity(0.28))
                        .frame(height: geo.size.height * holdProgress)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
                .clipShape(shape)
            }

            content
                .padding(side * 0.09)
        }
        .overlay(shape.strokeBorder(edgeColor, lineWidth: edgeWidth))
        .overlay(alignment: .topTrailing) { cornerBadge.padding(side * 0.07) }
        .shadow(color: .black.opacity(pressed ? 0.2 : 0.45), radius: pressed ? 2 : 8, x: 0, y: pressed ? 1 : 5)
        // Signature move: the cap lights faintly while the Mac works, then blooms when it fires.
        .shadow(color: DeckTheme.lit.opacity(litGlow), radius: feedback == .succeeded ? 16 : 6, x: 0, y: 0)
        .scaleEffect(pressed ? 0.965 : 1)
        .animation(.easeOut(duration: 0.12), value: pressed)
        .animation(.easeOut(duration: 0.35), value: feedback)
        .frame(width: size.width, height: size.height)
        .contentShape(shape)
    }

    private var content: some View {
        VStack(spacing: side * 0.05) {
            Spacer(minLength: 0)
            if let icon = key.iconSystemName {
                Image(systemName: icon)
                    .font(.system(size: side * 0.24, weight: .semibold))
                    .foregroundStyle(isLitByState ? DeckTheme.lit : tint)
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)
            }
            Text(key.label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DeckTheme.label)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            Text(subtitle)
                .font(.caption2.weight(.medium))
                .foregroundStyle(isLitByState ? DeckTheme.lit : DeckTheme.secondaryLabel)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 0)
        }
    }

    /// Live state for bound keys, "Hold" for disruptive keys, otherwise the shortcut sent.
    private var subtitle: String {
        if let liveChip { return liveChip.label }
        if key.requiresConfirm { return "Hold · \(key.action.shortcutHint ?? "")" }
        return key.action.shortcutHint ?? " "
    }

    private var litGlow: Double {
        switch feedback {
        case .pending: return 0.25
        case .succeeded: return 0.6
        default: return 0
        }
    }

    private var edgeColor: Color {
        switch feedback {
        case .pending: return DeckTheme.lit.opacity(0.45)
        case .succeeded: return DeckTheme.lit
        case .failed: return DeckTheme.failure
        default: return isLitByState ? DeckTheme.lit.opacity(0.8) : DeckTheme.hairline
        }
    }

    private var edgeWidth: CGFloat {
        switch feedback {
        case .pending, .succeeded, .failed: return 2
        default: return isLitByState ? 1.5 : 1
        }
    }

    @ViewBuilder private var cornerBadge: some View {
        switch feedback {
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.footnote.weight(.bold))
                .foregroundStyle(DeckTheme.failure)
        default:
            EmptyView()
        }
    }

    // MARK: - Interaction

    private func fire() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onFire()
    }

    private var holdGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard holdStart == nil else { return }
                holdStart = Date()
                holdFired = false
                isHolding = true
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.linear(duration: Self.holdDuration)) { holdProgress = 1 }
                let started = holdStart
                DispatchQueue.main.asyncAfter(deadline: .now() + Self.holdDuration) {
                    guard holdStart == started, isHolding else { return }
                    holdFired = true
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    onFire()
                }
            }
            .onEnded { _ in
                if !holdFired { onHoldHint() }
                holdStart = nil
                isHolding = false
                withAnimation(.easeOut(duration: 0.18)) { holdProgress = 0 }
            }
    }

    private var accessibilityHint: String {
        let target = key.action.shortcutHint.map { "Sends \($0) to \(appName) on your Mac." } ?? "Runs on your Mac."
        return key.requiresConfirm ? "\(target) Without VoiceOver, press and hold to fire." : target
    }
}

/// Hands the pressed state to the cap so it can sink while held.
private struct CapButtonStyle: ButtonStyle {
    let cap: (Bool) -> AnyView

    func makeBody(configuration: Configuration) -> some View {
        cap(configuration.isPressed)
    }
}

/// Horizontal shake for a key whose action failed.
private struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 6 * sin(animatableData * .pi * 4), y: 0))
    }
}

/// An empty slot in the 3 x 5 grid, so keys never move when a layout has fewer of them.
struct EmptyKeyWell: View {
    let size: CGSize
    private var side: CGFloat { min(size.width, size.height) }

    var body: some View {
        RoundedRectangle(cornerRadius: side * 0.16, style: .continuous)
            .fill(DeckTheme.well)
            .overlay(
                RoundedRectangle(cornerRadius: side * 0.16, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.035), lineWidth: 1)
            )
            .frame(width: size.width, height: size.height)
            .accessibilityHidden(true)
    }
}
