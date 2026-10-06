import Foundation
import SwiftData

/// Fields collected before a `Pet` is saved.
struct PetDraft: Equatable, Codable, Sendable {
    var name: String = ""
    var species: PetSpecies = .dog
    var breed: String = ""
    var usesGotchaDay: Bool = false
    var hasDate: Bool = true
    var date: Date = .now
    var personalityTags: [String] = []
    var avatarJPEG: Data?

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isValid: Bool {
        !trimmedName.isEmpty
    }

    func makePet() -> Pet {
        let cleanedBreed = breed.trimmingCharacters(in: .whitespacesAndNewlines)
        let birthday = hasDate && !usesGotchaDay ? date : nil
        let gotcha = hasDate && usesGotchaDay ? date : nil
        return Pet(
            name: trimmedName,
            species: species,
            breed: cleanedBreed,
            birthday: birthday,
            gotchaDay: gotcha,
            avatarJPEG: avatarJPEG,
            personalityTags: personalityTags
        )
    }

    /// Draft without the photo, small enough to keep in UserDefaults between launches.
    var persisted: Persisted {
        Persisted(
            name: name,
            speciesRaw: species.rawValue,
            breed: breed,
            usesGotchaDay: usesGotchaDay,
            hasDate: hasDate,
            date: date,
            personalityTags: personalityTags
        )
    }

    struct Persisted: Codable, Equatable, Sendable {
        var name: String
        var speciesRaw: String
        var breed: String
        var usesGotchaDay: Bool
        var hasDate: Bool
        var date: Date
        var personalityTags: [String]

        func restored(keepingAvatar avatar: Data?) -> PetDraft {
            var draft = PetDraft()
            draft.name = name
            draft.species = PetSpecies(rawValue: speciesRaw) ?? .dog
            draft.breed = breed
            draft.usesGotchaDay = usesGotchaDay
            draft.hasDate = hasDate
            draft.date = date
            draft.personalityTags = personalityTags
            draft.avatarJPEG = avatar
            return draft
        }
    }
}

enum PersonalityCatalog {
    static let suggestions = [
        "Cuddle bug",
        "Drama queen",
        "Food thief",
        "Zoomies",
        "Nap champion",
        "Velcro",
        "Clown",
        "Shy at first",
        "Brave",
        "Window watcher"
    ]
}

enum FavoriteSuggestions {
    static let all = ["Walks", "Treats", "Sunbeams", "Boxes", "Squeaky toys", "Laps"]
}
