import SwiftUI

struct SelectableChip: View {
    let title: String
    var isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(PawFont.body(.subheadline, weight: .semibold))
                .foregroundStyle(isSelected ? PawColor.onPrimary : PawColor.textPrimary)
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .background(isSelected ? PawColor.primary : PawColor.surface, in: Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? Color.clear : PawColor.separator, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
