import Foundation
import SwiftData

/// A diary row: a photo already in the library, a note, or both.
///
/// `assetLocalIdentifier` points at a PhotoKit asset. The image stays in Photos.
@Model
final class MemoryEntry {
    var id: UUID
    var assetLocalIdentifier: String?
    var date: Date
    var note: String
    var moodRaw: String?
    var locationName: String?
    var isFavorite: Bool
    var aiTags: [String]
    var createdAt: Date
    /// Higher means a crisper frame. Used to drop blurry shots and pick a burst winner.
    var sharpnessScore: Double = 1
    var isBestOfBurst: Bool = true
    var needsConfirmation: Bool = false
    var albumTags: [String] = []
    var burstIdentifier: String = ""

    var pets: [Pet] = []

    init(
        id: UUID = UUID(),
        assetLocalIdentifier: String? = nil,
        date: Date = .now,
        note: String = "",
        mood: Mood? = nil,
        locationName: String? = nil,
        isFavorite: Bool = false,
        aiTags: [String] = [],
        pets: [Pet] = [],
        createdAt: Date = .now,
        sharpnessScore: Double = 1,
        isBestOfBurst: Bool = true,
        needsConfirmation: Bool = false,
        albumTags: [String] = [],
        burstIdentifier: String = ""
    ) {
        self.id = id
        self.assetLocalIdentifier = assetLocalIdentifier
        self.date = date
        self.note = note
        self.moodRaw = mood?.rawValue
        self.locationName = locationName
        self.isFavorite = isFavorite
        self.aiTags = aiTags
        self.pets = pets
        self.createdAt = createdAt
        self.sharpnessScore = sharpnessScore
        self.isBestOfBurst = isBestOfBurst
        self.needsConfirmation = needsConfirmation
        self.albumTags = albumTags
        self.burstIdentifier = burstIdentifier
    }

    var mood: Mood? {
        get { moodRaw.flatMap(Mood.init(rawValue:)) }
        set { moodRaw = newValue?.rawValue }
    }
}
