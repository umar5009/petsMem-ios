import Foundation

struct PrintQuote: Sendable, Equatable {
    var product: PrintProductType
    var amount: Decimal
    var currencyCode: String
    var premiumDiscountApplied: Bool

    var formattedAmount: String {
        amount.formatted(.currency(code: currencyCode))
    }
}

struct PrintOrderDraft: Sendable, Equatable {
    var product: PrintProductType
    var designJSON: String
    var petID: UUID?
    var premium: Bool
}

struct PrintOrderReceipt: Sendable, Equatable {
    var orderID: UUID
    var status: PrintOrderStatus
    var amount: Decimal
    var currencyCode: String
    var trackingURL: URL?
}

/// Print fulfillment sits behind our backend (Gelato, Prodigi, Printful, or similar).
protocol PrintService: Sendable {
    func quote(for product: PrintProductType, premium: Bool) async throws -> PrintQuote
    func placeOrder(_ draft: PrintOrderDraft) async throws -> PrintOrderReceipt
}
