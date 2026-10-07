import SwiftUI
import iKeypadShared
#if canImport(UIKit)
import UIKit
#endif

/// A high-performance, 120Hz native rotary dial control for iPadOS
/// Allows scrubbing playheads, adjusting brush sizes, volume, or font sizes.
public struct DeckRotaryDialView: View {
    let title: String
    let iconSystemName: String
    let range: ClosedRange<Double>
    @Binding var value: Double
    let onValueChanged: (Double) -> Void

    @State private var dragAngle: Angle = .zero
    @State private var lastDragLocation: CGPoint = .zero

    public init(
        title: String,
        iconSystemName: String,
        range: ClosedRange<Double> = 0.0...100.0,
        value: Binding<Double>,
        onValueChanged: @escaping (Double) -> Void
    ) {
        self.title = title
        self.iconSystemName = iconSystemName
        self.range = range
        self._value = value
        self.onValueChanged = onValueChanged
    }

    public var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background Track
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 8)
                    .frame(width: 80, height: 80)

                // Active Progress Arc
                Circle()
                    .trim(from: 0.0, to: normalizedValue)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.blue, .cyan, .purple]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 80, height: 80)

                // Knob center indicator
                VStack(spacing: 2) {
                    Image(systemName: iconSystemName)
                        .font(.system(size: 20, weight: .bold))
                    Text("\(Int(value))")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                }
                .foregroundColor(.white)
            }
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        handleDrag(translation: gesture.translation)
                    }
                    .onEnded { _ in
                        lastDragLocation = .zero
                    }
            )

            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .background(Color.secondary.opacity(0.15))
        .cornerRadius(16)
    }

    private var normalizedValue: CGFloat {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return CGFloat((value - range.lowerBound) / span)
    }

    private func handleDrag(translation: CGSize) {
        // Vertical drag adjusts dial value
        let delta = -Double(translation.height - lastDragLocation.y) * 0.5
        lastDragLocation = CGPoint(x: translation.width, y: translation.height)

        let newValue = min(max(value + delta, range.lowerBound), range.upperBound)
        if newValue != value {
            value = newValue
            #if os(iOS)
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            #endif
            onValueChanged(newValue)
        }
    }
}
