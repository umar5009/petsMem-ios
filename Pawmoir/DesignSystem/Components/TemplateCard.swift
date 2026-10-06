import SwiftUI

struct TemplateCard: View {
    var title: String
    var systemImage: String
    var isLocked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(PawColor.primary)
                    .accessibilityHidden(true)
                Spacer()
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PawColor.textSecondary)
                        .accessibilityLabel("Premium")
                }
            }
            Text(title)
                .font(PawFont.title(.subheadline))
                .foregroundStyle(PawColor.textPrimary)
                .multilineTextAlignment(.leading)
        }
        .padding(14)
        .frame(width: 148, height: 112, alignment: .topLeading)
        .background(isLocked ? PawColor.surface : PawColor.coralSoft, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(PawColor.separator, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    HStack {
        TemplateCard(title: "Polaroid", systemImage: "photo", isLocked: false)
        TemplateCard(title: "Comic", systemImage: "bubble.left.and.bubble.right", isLocked: true)
    }
    .padding()
    .background(PawColor.background)
}
