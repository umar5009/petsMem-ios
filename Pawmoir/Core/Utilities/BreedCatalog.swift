import Foundation

/// Searchable breed list used during onboarding. It is local and offline.
enum BreedCatalog {
    static func suggestions(for species: PetSpecies, query: String, limit: Int = 8) -> [String] {
        let pool = breeds(for: species)
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let matches: [String]
        if trimmed.isEmpty {
            matches = pool
        } else {
            matches = pool.filter { $0.localizedCaseInsensitiveContains(trimmed) }
        }
        return Array(matches.prefix(limit))
    }

    static func breeds(for species: PetSpecies) -> [String] {
        switch species {
        case .dog: dogs
        case .cat: cats
        case .other: other
        }
    }

    private static let dogs = [
        "Mixed", "Not sure", "Labrador Retriever", "Golden Retriever", "German Shepherd",
        "French Bulldog", "Bulldog", "Poodle", "Beagle", "Rottweiler", "Dachshund",
        "Corgi", "Australian Shepherd", "Yorkshire Terrier", "Boxer",
        "Cavalier King Charles Spaniel", "Doberman", "Great Dane", "Siberian Husky",
        "Shih Tzu", "Boston Terrier", "Pomeranian", "Border Collie", "Chihuahua", "Pug",
        "Maltese", "Shiba Inu", "Havanese", "Bernese Mountain Dog", "Cocker Spaniel",
        "Miniature Schnauzer", "Staffordshire Bull Terrier", "Greyhound", "Whippet",
        "Samoyed", "Akita", "Dalmatian", "Vizsla", "Weimaraner", "Australian Cattle Dog",
        "Jack Russell Terrier"
    ]

    private static let cats = [
        "Mixed", "Not sure", "Domestic Shorthair", "Domestic Longhair", "Siamese",
        "Maine Coon", "Ragdoll", "Persian", "British Shorthair", "Sphynx", "Bengal",
        "Abyssinian", "Scottish Fold", "Russian Blue", "American Shorthair", "Birman",
        "Oriental", "Savannah", "Burmese", "Norwegian Forest Cat", "Devon Rex"
    ]

    private static let other = [
        "Mixed", "Not sure", "Rabbit", "Guinea Pig", "Hamster", "Bird", "Parrot",
        "Horse", "Reptile", "Turtle", "Fish", "Ferret"
    ]
}
