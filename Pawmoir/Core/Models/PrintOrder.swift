import Foundation
import SwiftData

/// A print-shop order. `designJSON` holds the page layout once the editor exists.
@Model
final class PrintOrder {
    var id: UUID
    var productTypeRaw: String
    var designJSON: String
    var priceCents: Int
    var currencyCode: String
    var statusRaw: String
    var trackingURL: String?
    var petID: UUID?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        productType: PrintProductType,
        designJSON: String = "{}",
        priceCents: Int = 0,
        currencyCode: String = "USD",
        status: PrintOrderStatus = .draft,
        trackingURL: String? = nil,
        petID: UUID? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.productTypeRaw = productType.rawValue
        self.designJSON = designJSON
        self.priceCents = priceCents
        self.currencyCode = currencyCode
        self.statusRaw = status.rawValue
        self.trackingURL = trackingURL
        self.petID = petID
        self.createdAt = createdAt
    }

    var productType: PrintProductType {
        get { PrintProductType(rawValue: productTypeRaw) ?? .hardcoverBook }
        set { productTypeRaw = newValue.rawValue }
    }

    var status: PrintOrderStatus {
        get { PrintOrderStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }
}
