import Foundation
import SwiftData

/// One animal in the household.
///
/// Photos are not copied onto the pet. `featurePrintData` is reserved for the
/// on-device Vision print that will tell pets apart in a later phase.
@Model
final class Pet {
    var id: UUID
    var name: String
    var speciesRaw: String
    var breed: String
    var birthday: Date?
    var gotchaDay: Date?
    var avatarJPEG: Data?
    var personalityTags: [String]
    var favoriteThings: [String]
    var weightKilograms: Double?
    var isMemorial: Bool
    var featurePrintData: Data?
    var shareCode: String = ""
    var familyMemberNames: [String] = []
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Milestone.pet)
    var milestones: [Milestone] = []

    @Relationship(deleteRule: .nullify, inverse: \MemoryEntry.pets)
    var memories: [MemoryEntry] = []

    @Relationship(deleteRule: .nullify, inverse: \Creation.pet)
    var creations: [Creation] = []

    init(
        id: UUID = UUID(),
        name: String,
        species: PetSpecies,
        breed: String = "",
        birthday: Date? = nil,
        gotchaDay: Date? = nil,
        avatarJPEG: Data? = nil,
        personalityTags: [String] = [],
        favoriteThings: [String] = [],
        weightKilograms: Double? = nil,
        isMemorial: Bool = false,
        featurePrintData: Data? = nil,
        shareCode: String = "",
        familyMemberNames: [String] = [],
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.speciesRaw = species.rawValue
        self.breed = breed
        self.birthday = birthday
        self.gotchaDay = gotchaDay
        self.avatarJPEG = avatarJPEG
        self.personalityTags = personalityTags
        self.favoriteThings = favoriteThings
        self.weightKilograms = weightKilograms
        self.isMemorial = isMemorial
        self.featurePrintData = featurePrintData
        self.shareCode = shareCode
        self.familyMemberNames = familyMemberNames
        self.createdAt = createdAt
    }

    var species: PetSpecies {
        get { PetSpecies(rawValue: speciesRaw) ?? .other }
        set { speciesRaw = newValue.rawValue }
    }

    /// Birthday when we know it, otherwise the day they came home.
    var ageAnchor: Date? {
        birthday ?? gotchaDay
    }
}
