import Foundation

struct BookPageModel: Codable, Identifiable, Equatable, Sendable {
    var id: UUID
    var layout: String
    var assetIdentifiers: [String]
    var caption: String
}

struct BookDesignModel: Codable, Equatable, Sendable {
    var title: String
    var productRaw: String
    var pages: [BookPageModel]

    var json: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(self), let text = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return text
    }

    static func decode(_ json: String) -> BookDesignModel? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(BookDesignModel.self, from: data)
    }
}

enum BookAutolayout {
    static func make(title: String, product: PrintProductType, items: [(assetID: String, note: String)]) -> BookDesignModel {
        let pageCount: Int
        switch product {
        case .canvas: pageCount = 1
        case .cardPack: pageCount = 8
        case .calendar, .hardcoverBook, .softcoverBook: pageCount = 12
        }
        var pages: [BookPageModel] = []
        if items.isEmpty {
            for index in 0..<pageCount {
                pages.append(
                    BookPageModel(
                        id: UUID(),
                        layout: index == 0 ? "cover" : "caption",
                        assetIdentifiers: [],
                        caption: index == 0 ? title : ""
                    )
                )
            }
        } else {
            for index in 0..<pageCount {
                let item = items[index % items.count]
                let layout = index == 0 ? "cover" : (index % 3 == 0 ? "duo" : "full")
                let second = items[(index + 1) % items.count].assetID
                pages.append(
                    BookPageModel(
                        id: UUID(),
                        layout: layout,
                        assetIdentifiers: layout == "duo" ? [item.assetID, second] : [item.assetID],
                        caption: item.note.isEmpty ? title : item.note
                    )
                )
            }
        }
        return BookDesignModel(title: title, productRaw: product.rawValue, pages: pages)
    }
}

enum PrintQuality {
    static func warning(pixelWidth: Int, pixelHeight: Int) -> String? {
        let shortSide = min(pixelWidth, pixelHeight)
        if shortSide <= 0 { return nil }
        if shortSide < 800 {
            return "This photo is too small to print sharply."
        }
        if shortSide < 1500 {
            return "This photo may look soft on a large page."
        }
        return nil
    }
}

struct ShippingOption: Identifiable, Equatable, Sendable {
    var id: String
    var title: String
    var detail: String
    var amount: Decimal

    static let all = [
        ShippingOption(id: "standard", title: "Standard", detail: "5–8 days", amount: Decimal(string: "4.99") ?? 4.99),
        ShippingOption(id: "express", title: "Express", detail: "2–3 days", amount: Decimal(string: "9.99") ?? 9.99)
    ]
}
