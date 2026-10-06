import Foundation

struct CaptionRequest: Sendable, Equatable {
    var petName: String
    var species: PetSpecies
    var personalityTags: [String]
    var tone: CaptionTone
}

/// Captions, story text, and styles go through our backend later.
/// The app never embeds an API key. `MockAIService` keeps the UI runnable offline.
protocol AIService: Sendable {
    func captions(for request: CaptionRequest) async throws -> [String]
}
