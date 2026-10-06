import SwiftUI

struct EmptyStateView: View {
    var systemImage: String
    var title: String
    var message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(PawColor.primary)
                .frame(width: 84, height: 84)
                .background(PawColor.coralSoft, in: Circle())
                .accessibilityHidden(true)
            Text(title)
                .font(PawFont.title())
                .foregroundStyle(PawColor.textPrimary)
                .multilineTextAlignment(.center)
            Text(message)
                .font(PawFont.body())
                .foregroundStyle(PawColor.textSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                PrimaryButton(title: LocalizedStringKey(actionTitle), action: action)
                    .padding(.top, 8)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    EmptyStateView(
        systemImage: "book.closed",
        title: "Nothing here yet",
        message: "A note, a walk, a nap. The diary starts with one of them.",
        actionTitle: "Add a memory",
        action: {}
    )
    .background(PawColor.background)
}
