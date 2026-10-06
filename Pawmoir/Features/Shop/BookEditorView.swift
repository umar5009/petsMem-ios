import PassKit
import SwiftUI
import SwiftData

struct BookEditorView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MemoryEntry.date, order: .reverse) private var memories: [MemoryEntry]
    var product: PrintProductType
    var petName: String?

    @State private var design: BookDesignModel
    @State private var pageIndex = 0
    @State private var showCheckout = false
    @State private var qualityNote: String?

    init(product: PrintProductType, petName: String?) {
        self.product = product
        self.petName = petName
        let title = petName.map { "\($0)'s \(product.title)" } ?? product.title
        _design = State(initialValue: BookAutolayout.make(title: title, product: product, items: []))
    }

    var body: some View {
        VStack(spacing: 0) {
            if memories.isEmpty == false && design.pages.allSatisfy({ $0.assetIdentifiers.isEmpty }) {
                Color.clear.frame(height: 0)
                    .onAppear { refill() }
            }
            TabView(selection: $pageIndex) {
                ForEach(Array(design.pages.enumerated()), id: \.element.id) { index, page in
                    pageView(page, index: index)
                        .rotation3DEffect(.degrees(pageIndex == index ? 0 : 8), axis: (x: 0, y: 1, z: 0))
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 420)
            if let page = currentPage {
                TextField("Caption", text: captionBinding(pageID: page.id), axis: .vertical)
                    .lineLimit(2...4)
                    .padding(12)
                    .background(PawColor.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 20)
            }
            if let qualityNote {
                Text(qualityNote)
                    .font(PawFont.body(.footnote))
                    .foregroundStyle(PawColor.destructive)
                    .padding(.horizontal, 20)
            }
            PrimaryButton(title: "Continue to checkout") {
                showCheckout = true
            }
            .padding(20)
        }
        .navigationTitle(design.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(PawColor.background)
        .navigationDestination(isPresented: $showCheckout) {
            CheckoutView(product: product, design: design, petName: petName)
        }
        .onAppear { refill() }
    }

    private var currentPage: BookPageModel? {
        guard design.pages.indices.contains(pageIndex) else { return nil }
        return design.pages[pageIndex]
    }

    private func pageView(_ page: BookPageModel, index: Int) -> some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(PawColor.surfaceElevated)
                    .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
                VStack(spacing: 8) {
                    if let asset = page.assetIdentifiers.first {
                        AssetThumbnail(localIdentifier: asset, side: 260)
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else {
                        Image(systemName: product.symbolName)
                            .font(.largeTitle)
                            .foregroundStyle(PawColor.primary)
                    }
                    Text(page.caption.isEmpty ? design.title : page.caption)
                        .font(PawFont.body(.subheadline))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(PawColor.textPrimary)
                        .padding(.horizontal, 12)
                }
                .padding(16)
            }
            .padding(.horizontal, 28)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Page \(index + 1) of \(design.pages.count)")
        }
    }

    private func captionBinding(pageID: UUID) -> Binding<String> {
        Binding(
            get: { design.pages.first { $0.id == pageID }?.caption ?? "" },
            set: { newValue in
                guard let index = design.pages.firstIndex(where: { $0.id == pageID }) else { return }
                design.pages[index].caption = newValue
            }
        )
    }

    private func refill() {
        let items = memories.compactMap { memory -> (assetID: String, note: String)? in
            guard let id = memory.assetLocalIdentifier else { return nil }
            return (id, memory.note)
        }
        guard !items.isEmpty else { return }
        design = BookAutolayout.make(title: design.title, product: product, items: items)
        qualityNote = PrintQuality.warning(pixelWidth: 640, pixelHeight: 480)
    }
}

struct CheckoutView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.modelContext) private var modelContext
    var product: PrintProductType
    var design: BookDesignModel
    var petName: String?

    @State private var quote: PrintQuote?
    @State private var shipping = ShippingOption.all[0]
    @State private var name = ""
    @State private var line = ""
    @State private var city = ""
    @State private var postal = ""
    @State private var order: PrintOrder?
    @State private var errorMessage: String?
    @State private var isPlacing = false
    @State private var applePay = ApplePayPresenter()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if !dependencies.network.isOnline {
                    OfflineBanner(message: "Ordering needs a connection. Your design stays on this iPhone.")
                }
                if let quote {
                    Text(quote.formattedAmount)
                        .font(PawFont.display(.title))
                    if quote.premiumDiscountApplied {
                        Text("Includes 15% off for Premium.")
                            .font(PawFont.body(.subheadline))
                            .foregroundStyle(PawColor.secondary)
                    }
                } else {
                    LoadingShimmer(height: 36)
                }
                Text("Shipping")
                    .font(PawFont.title(.headline))
                ForEach(ShippingOption.all) { option in
                    SelectableChip(title: "\(option.title) · \(option.detail)", isSelected: shipping.id == option.id) {
                        shipping = option
                    }
                }
                field("Name", text: $name)
                field("Street", text: $line)
                field("City", text: $city)
                field("Postal code", text: $postal)
                Text("Paper size \(PaperStandard.preferred()). Apple Pay is offered when this iPhone can pay. Otherwise the order is saved as a preview and is not charged.")
                    .font(PawFont.body(.footnote))
                    .foregroundStyle(PawColor.textSecondary)
                if ApplePayPresenter.isAvailable, let quote {
                    Button("Pay with Apple Pay") {
                        applePay.pay(amount: quote.amount + shipping.amount, label: product.title) { success in
                            if success {
                                Task { await place() }
                            }
                        }
                    }
                    .frame(minHeight: 44)
                } else {
                    Text("Apple Pay isn't set up on this iPhone. Placing an order saves a preview and does not charge you.")
                        .font(PawFont.body(.footnote))
                        .foregroundStyle(PawColor.textSecondary)
                }
                PrimaryButton(title: "Place order", isEnabled: canPlace, isLoading: isPlacing) {
                    Task { await place() }
                }
                if let order {
                    NavigationLink("Track order") {
                        OrderTrackingView(order: order)
                    }
                    .frame(minHeight: 44)
                }
            }
            .padding(20)
        }
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .background(PawColor.background)
        .task {
            quote = try? await dependencies.printing.quote(for: product, premium: dependencies.entitlements.isPremium)
        }
        .alert("Order", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var canPlace: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !line.isEmpty && !city.isEmpty && !postal.isEmpty && dependencies.network.isOnline
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .padding(12)
            .background(PawColor.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func place() async {
        guard dependencies.network.isOnline else {
            errorMessage = "You're offline. Try again when you're connected."
            return
        }
        isPlacing = true
        defer { isPlacing = false }
        do {
            let receipt = try await dependencies.printing.placeOrder(
                PrintOrderDraft(product: product, designJSON: design.json, petID: nil, premium: dependencies.entitlements.isPremium)
            )
            let saved = PrintOrder(
                id: receipt.orderID,
                productType: product,
                designJSON: design.json,
                priceCents: cents(receipt.amount),
                currencyCode: receipt.currencyCode,
                status: .received
            )
            modelContext.insert(saved)
            try modelContext.save()
            order = saved
            Haptics.success()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func cents(_ amount: Decimal) -> Int {
        var value = amount
        var rounded = Decimal()
        NSDecimalRound(&rounded, &value, 2, .plain)
        return NSDecimalNumber(decimal: rounded * 100).intValue
    }
}

final class ApplePayPresenter: NSObject, PKPaymentAuthorizationControllerDelegate {
    static var isAvailable: Bool { PKPaymentAuthorizationController.canMakePayments() }

    private var onFinish: (Bool) -> Void = { _ in }
    private var didAuthorize = false

    func pay(amount: Decimal, label: String, completion: @escaping (Bool) -> Void) {
        onFinish = completion
        didAuthorize = false
        let request = PKPaymentRequest()
        request.merchantIdentifier = "merchant.com.pawmoir.app"
        request.countryCode = "US"
        request.currencyCode = "USD"
        request.supportedNetworks = [.visa, .masterCard, .amex]
        request.merchantCapabilities = .threeDSecure
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: label, amount: NSDecimalNumber(decimal: amount)),
            PKPaymentSummaryItem(label: "Pawmoir", amount: NSDecimalNumber(decimal: amount))
        ]
        let controller = PKPaymentAuthorizationController(paymentRequest: request)
        controller.delegate = self
        controller.present { [weak self] presented in
            if !presented {
                self?.onFinish(false)
            }
        }
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        didAuthorize = true
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
    }

    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss()
        onFinish(didAuthorize)
    }
}

struct OrderTrackingView: View {
    var order: PrintOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(order.productType.title)
                .font(PawFont.display(.title))
            Text(order.status.rawValue.capitalized)
                .font(PawFont.title())
                .foregroundStyle(PawColor.secondary)
            Text("We'll show a carrier link here when the print shop ships. This preview order is not a charge.")
                .font(PawFont.body())
                .foregroundStyle(PawColor.textSecondary)
            if let link = order.trackingURL, let url = URL(string: link) {
                Link("Track shipment", destination: url)
            }
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PawColor.background)
        .navigationTitle("Order")
    }
}
