import Foundation
import SwiftData

/// Something made in the studio: a caption, a video, a recap, or a collage.
@Model
final class Creation {
    var id: UUID
    var typeRaw: String
    var templateID: String?
    var assetIdentifiers: [String]
    var exportPath: String?
    var createdAt: Date
    var petID: UUID?

    var pet: Pet?

    init(
        id: UUID = UUID(),
        type: CreationType,
        templateID: String? = nil,
        assetIdentifiers: [String] = [],
        exportPath: String? = nil,
        createdAt: Date = .now,
        petID: UUID? = nil,
        pet: Pet? = nil
    ) {
        self.id = id
        self.typeRaw = type.rawValue
        self.templateID = templateID
        self.assetIdentifiers = assetIdentifiers
        self.exportPath = exportPath
        self.createdAt = createdAt
        self.petID = petID
        self.pet = pet
    }

    var type: CreationType {
        get { CreationType(rawValue: typeRaw) ?? .caption }
        set { typeRaw = newValue.rawValue }
    }
}
