import SwiftUI

/// Soft paywall. Skipping is allowed wherever the diary must stay open.
struct PaywallView: View {
    var petName: String?
    var allowsSkip: Bool
    @Binding var selectedPlan: PaywallPlan
    var isWorking: Bool = false
    var onStartTrial: () -> Void
    var onSkip: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Try Pawmoir Premium")
                        .font(PawFont.display(.title))
                        .foregroundStyle(PawColor.textPrimary)
                    Text(subtitle)
                        .font(PawFont.body())
                        .foregroundStyle(PawColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 12) {
                    benefit("Unlimited pets")
                    benefit("Unlimited captions")
                    benefit("Birthday films and the yearly recap, without the watermark")
                    benefit("Every template, and the full music library")
                    benefit("Family sharing and iCloud sync")
                    benefit("15% off prints")
                }
                .padding(16)
                .background(PawColor.surfaceElevated, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                ForEach(PaywallPlan.allCases) { plan in
                    planCard(plan)
                }

                Text(Self.subscriptionTerms)
                    .font(PawFont.body(.caption))
                    .foregroundStyle(PawColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 16) {
                    Link("Privacy Policy", destination: LegalLinks.privacy)
                    Link("Terms of Use", destination: LegalLinks.terms)
                }
                .font(PawFont.body(.footnote, weight: .semibold))
                .tint(PawColor.primary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                PrimaryButton(
                    title: "Start free trial",
                    isLoading: isWorking,
                    identifier: "onboarding.paywall.trial",
                    action: onStartTrial
                )
                if allowsSkip {
                    PrimaryButton(
                        title: "Maybe later",
                        style: .plain,
                        identifier: "onboarding.paywall.skip",
                        action: onSkip
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            .background(PawColor.background)
        }
        .accessibilityElement(children: .contain)
    }

    private var subtitle: String {
        if let petName, !petName.isEmpty {
            return "Keep every side of \(petName). The diary stays free either way."
        }
        return "The diary stays free. Premium is for the extra pets, films, and prints."
    }

    private func benefit(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "checkmark")
                .font(.footnote.weight(.bold))
                .foregroundStyle(PawColor.secondary)
                .accessibilityHidden(true)
            Text(text)
                .font(PawFont.body(.subheadline))
                .foregroundStyle(PawColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func planCard(_ plan: PaywallPlan) -> some View {
        let selected = selectedPlan == plan
        return Button {
            selectedPlan = plan
            Haptics.tap()
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(PawFont.title(.headline))
                        if plan.isBestValue {
                            Text("Best value")
                                .font(PawFont.body(.caption, weight: .semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(PawColor.accent, in: Capsule())
                                .foregroundStyle(PawColor.onPrimary)
                        }
                    }
                    Text(plan.detail)
                        .font(PawFont.body(.subheadline))
                        .foregroundStyle(PawColor.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selected ? PawColor.primary : PawColor.textTertiary)
                    .accessibilityHidden(true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .background(PawColor.surfaceElevated, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(selected ? PawColor.primary : PawColor.separator, lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    /// App Store Guideline 3.1.2: length, price, and renewal must be on the paywall.
    static let subscriptionTerms = "Pawmoir Premium is $4.99 per month or $34.99 per year after a 7-day free trial. Payment is charged to your Apple ID when the trial ends. The subscription renews automatically unless you cancel at least 24 hours before the end of the current period. Manage or cancel anytime in Settings > Apple ID > Subscriptions."
}

enum LegalLinks {
    static let privacy = required("https://pawmoir.app/privacy")
    static let terms = required("https://pawmoir.app/terms")

    private static func required(_ string: String) -> URL {
        guard let url = URL(string: string) else {
            preconditionFailure("Invalid legal URL \(string)")
        }
        return url
    }
}

#Preview("Paywall") {
    @Previewable @State var plan = PaywallPlan.yearly
    PaywallView(
        petName: "Bella",
        allowsSkip: true,
        selectedPlan: $plan,
        onStartTrial: {},
        onSkip: {}
    )
    .background(PawColor.background)
}
