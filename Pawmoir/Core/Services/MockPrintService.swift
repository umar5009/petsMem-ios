import Foundation

/// Prices a product locally. Nothing is charged and nothing is sent to a printer.
actor MockPrintService: PrintService {
    static let premiumDiscount = Decimal(string: "0.85") ?? 0.85

    func quote(for product: PrintProductType, premium: Bool) async throws -> PrintQuote {
        let amount = premium ? product.listPriceUSD * Self.premiumDiscount : product.listPriceUSD
        return PrintQuote(
            product: product,
            amount: amount,
            currencyCode: "USD",
            premiumDiscountApplied: premium
        )
    }

    func placeOrder(_ draft: PrintOrderDraft) async throws -> PrintOrderReceipt {
        let priced = try await quote(for: draft.product, premium: draft.premium)
        return PrintOrderReceipt(
            orderID: UUID(),
            status: .received,
            amount: priced.amount,
            currencyCode: priced.currencyCode,
            trackingURL: nil
        )
    }
}
