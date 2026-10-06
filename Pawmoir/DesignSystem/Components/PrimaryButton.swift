import SwiftUI

struct PrimaryButton: View {
    enum Style {
        case primary
        case secondary
        case plain
    }

    let title: LocalizedStringKey
    var style: Style = .primary
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var identifier: String?
    let action: () -> Void

    var body: some View {
        Button(action: pressed) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(foreground)
                } else {
                    Text(title)
                        .font(.system(.headline, design: .rounded))
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal, 16)
            .foregroundStyle(foreground)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                if style == .plain {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(PawColor.separator, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1 : 0.45)
        .modifier(IdentifierIfNeeded(identifier: identifier))
        .accessibilityAddTraits(.isButton)
    }

    private func pressed() {
        if style == .primary {
            Haptics.tap()
        }
        action()
    }

    private var foreground: Color {
        switch style {
        case .primary, .secondary:
            PawColor.onPrimary
        case .plain:
            PawColor.textPrimary
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            PawColor.primary
        case .secondary:
            PawColor.secondary
        case .plain:
            PawColor.surface
        }
    }
}

private struct IdentifierIfNeeded: ViewModifier {
    var identifier: String?

    func body(content: Content) -> some View {
        if let identifier {
            content.accessibilityIdentifier(identifier)
        } else {
            content
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        PrimaryButton(title: "Begin", action: {})
        PrimaryButton(title: "Maybe later", style: .plain, action: {})
        PrimaryButton(title: "Saving", isLoading: true, action: {})
    }
    .padding()
    .background(PawColor.background)
}
