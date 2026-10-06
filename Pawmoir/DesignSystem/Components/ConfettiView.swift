import SwiftUI

/// A short burst for a birthday. Hidden from VoiceOver and skipped when Reduce Motion is on.
struct ConfettiView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var fall = false

    var body: some View {
        GeometryReader { geo in
            if !reduceMotion {
                ZStack {
                    ForEach(0..<16, id: \.self) { index in
                        Circle()
                            .fill(color(for: index))
                            .frame(width: 8, height: 8)
                            .position(
                                x: geo.size.width * xFraction(index),
                                y: fall ? geo.size.height + 12 : -12
                            )
                            .opacity(fall ? 0.15 : 1)
                    }
                }
                .onAppear {
                    withAnimation(.easeIn(duration: 1.5)) {
                        fall = true
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func color(for index: Int) -> Color {
        switch index % 3 {
        case 0: PawColor.primary
        case 1: PawColor.secondary
        default: PawColor.accent
        }
    }

    private func xFraction(_ index: Int) -> CGFloat {
        let slots: [CGFloat] = [0.08, 0.18, 0.28, 0.4, 0.52, 0.63, 0.74, 0.86]
        return slots[index % slots.count]
    }
}
