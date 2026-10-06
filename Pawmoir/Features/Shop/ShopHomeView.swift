import SwiftUI
import SwiftData

enum SeasonalShop {
    /// October and November: invite a calendar for the coming year.
    static func calendarHeadline(now: Date = .now, calendar: Calendar = .current) -> String? {
        let month = calendar.component(.month, from: now)
        guard month == 10 || month == 11 else { return nil }
        let year = calendar.component(.year, from: now) + 1
        return "Make a \(year) calendar"
    }
}

struct ShopHomeView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Query(sort: \Pet.createdAt) private var pets: [Pet]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !dependencies.network.isOnline {
                    OfflineBanner(message: "You're offline. You can browse. Ordering needs a connection.")
                }
                if dependencies.entitlements.isPremium {
                    Text("Premium · 15% off prints")
                        .font(PawFont.body(.subheadline, weight: .semibold))
                        .foregroundStyle(PawColor.onPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(PawColor.secondary, in: Capsule())
                }
                Text("Books and prints, laid out from the diary. Sized for \(PaperStandard.preferred()) paper.")
                    .font(PawFont.body())
                    .foregroundStyle(PawColor.textSecondary)
                if let headline = SeasonalShop.calendarHeadline() {
                    Label(headline, systemImage: "calendar")
                        .font(PawFont.title(.headline))
                        .foregroundStyle(PawColor.textPrimary)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(PawColor.sageSoft, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                ForEach(PrintProductType.allCases) { product in
                    NavigationLink {
                        ProductDetailView(product: product, petName: pets.first?.name)
                    } label: {
                        productRow(product)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
        .navigationTitle("Shop")
        .background(PawColor.background)
    }

    private func productRow(_ product: PrintProductType) -> some View {
        HStack(spacing: 14) {
            Image(systemName: product.symbolName)
                .font(.title3)
                .foregroundStyle(PawColor.primary)
                .frame(width: 48, height: 48)
                .background(PawColor.coralSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(product.title)
                    .font(PawFont.title(.headline))
                    .foregroundStyle(PawColor.textPrimary)
                Text(product.blurb)
                    .font(PawFont.body(.footnote))
                    .foregroundStyle(PawColor.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(PawColor.textTertiary)
                .accessibilityHidden(true)
        }
        .padding(12)
        .frame(minHeight: 44)
        .background(PawColor.surfaceElevated, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct ProductDetailView: View {
    @Environment(AppDependencies.self) private var dependencies
    var product: PrintProductType
    var petName: String?
    @State private var quote: PrintQuote?
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(PawColor.coralSoft)
                    .frame(height: 220)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: product.symbolName)
                                .font(.largeTitle)
                                .foregroundStyle(PawColor.primary)
                            Text(petName.map { "\($0)'s \(product.title.lowercased())" } ?? product.title)
                                .font(PawFont.title())
                                .multilineTextAlignment(.center)
                                .foregroundStyle(PawColor.textPrimary)
                        }
                        .padding()
                    }
                    .accessibilityElement(children: .combine)

                Text(product.blurb)
                    .font(PawFont.body())
                    .foregroundStyle(PawColor.textSecondary)

                if let quote {
                    Text(quote.formattedAmount)
                        .font(PawFont.display(.title))
                        .foregroundStyle(PawColor.textPrimary)
                    if quote.premiumDiscountApplied {
                        Text("Includes your 15% Premium saving.")
                            .font(PawFont.body(.subheadline))
                            .foregroundStyle(PawColor.secondary)
                    }
                } else if errorMessage == nil {
                    LoadingShimmer(height: 36)
                }

                NavigationLink {
                    BookEditorView(product: product, petName: petName)
                } label: {
                    Text("Lay out this book")
                        .font(PawFont.title(.headline))
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .foregroundStyle(PawColor.onPrimary)
                        .background(PawColor.primary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                Text("Photos that are too small to print are flagged before checkout. Apple Pay is offered when this iPhone can pay.")
                    .font(PawFont.body(.footnote))
                    .foregroundStyle(PawColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(PawColor.destructive)
                }
            }
            .padding(20)
        }
        .navigationTitle(product.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(PawColor.background)
        .task(id: dependencies.entitlements.isPremium) {
            await loadQuote()
        }
    }

    private func loadQuote() async {
        do {
            quote = try await dependencies.printing.quote(
                for: product,
                premium: dependencies.entitlements.isPremium
            )
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview("Shop") {
    let dependencies = AppDependencies.preview()
    NavigationStack {
        ShopHomeView()
    }
    .environment(dependencies)
    .modelContainer(dependencies.modelContainer)
}
