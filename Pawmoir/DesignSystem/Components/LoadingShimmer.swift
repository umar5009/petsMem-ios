import SwiftUI

/// A quiet placeholder while a quote or caption is on its way.
struct LoadingShimmer: View {
    var height: CGFloat = 18
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(PawColor.separator)
            .frame(height: height)
            .overlay {
                if !reduceMotion {
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [.clear, PawColor.surface.opacity(0.7), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 0.45)
                        .offset(x: phase * geo.size.width)
                    }
                    .clipped()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityLabel("Loading")
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
                    phase = 1.4
                }
            }
    }
}

#Preview {
    VStack(spacing: 10) {
        LoadingShimmer()
        LoadingShimmer(height: 72)
    }
    .padding()
    .background(PawColor.background)
}
