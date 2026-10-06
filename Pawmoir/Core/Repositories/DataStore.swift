import Foundation
import SwiftData

/// Deletes or exports everything SwiftData holds for this person.
@MainActor
enum DataStore {
    static func deleteAll(in context: ModelContext, entitlements: EntitlementManaging, onboarding: OnboardingStore) throws {
        try deleteAll(MemoryEntry.self, in: context)
        try deleteAll(Milestone.self, in: context)
        try deleteAll(Creation.self, in: context)
        try deleteAll(PrintOrder.self, in: context)
        try deleteAll(Pet.self, in: context)
        try context.save()
        entitlements.clearLocalEntitlement()
        onboarding.resetAll()
    }

    private static func deleteAll<Model: PersistentModel>(_ type: Model.Type, in context: ModelContext) throws {
        let items = try context.fetch(FetchDescriptor<Model>())
        for item in items {
            context.delete(item)
        }
    }

    static func exportFile(pets: [Pet], memories: [MemoryEntry]) throws -> URL {
        let payload = ExportFile(
            exportedAt: Date(),
            pets: pets.map(PetRecord.init),
            memories: memories.map(MemoryRecord.init)
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(payload)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("pawmoir-export.json")
        try data.write(to: url, options: .atomic)
        return url
    }
}

struct ExportFile: Codable {
    var exportedAt: Date
    var pets: [PetRecord]
    var memories: [MemoryRecord]
}

struct PetRecord: Codable {
    var id: UUID
    var name: String
    var species: String
    var breed: String
    var birthday: Date?
    var gotchaDay: Date?
    var personalityTags: [String]
    var favoriteThings: [String]
    var weightKilograms: Double?
    var isMemorial: Bool

    init(_ pet: Pet) {
        id = pet.id
        name = pet.name
        species = pet.species.rawValue
        breed = pet.breed
        birthday = pet.birthday
        gotchaDay = pet.gotchaDay
        personalityTags = pet.personalityTags
        favoriteThings = pet.favoriteThings
        weightKilograms = pet.weightKilograms
        isMemorial = pet.isMemorial
    }
}

struct MemoryRecord: Codable {
    var id: UUID
    var date: Date
    var note: String
    var mood: String?
    var locationName: String?
    var isFavorite: Bool
    var petIDs: [UUID]

    init(_ memory: MemoryEntry) {
        id = memory.id
        date = memory.date
        note = memory.note
        mood = memory.moodRaw
        locationName = memory.locationName
        isFavorite = memory.isFavorite
        petIDs = memory.pets.map(\.id)
    }
}
