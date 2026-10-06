import Foundation

/// On-device stand-in for the caption backend. Lines are templates, not a model.
actor MockAIService: AIService {
    func captions(for request: CaptionRequest) async throws -> [String] {
        if !LaunchArguments.isUITesting {
            try await Task.sleep(for: .milliseconds(280))
        }
        return MockCaptionLibrary.lines(for: request)
    }
}

enum MockCaptionLibrary {
    static func lines(for request: CaptionRequest) -> [String] {
        let name = request.petName.isEmpty ? "They" : request.petName
        let trait = request.personalityTags.first?.lowercased() ?? "soft heart"
        switch request.tone {
        case .funny:
            return [
                "\(name) has decided this is a photoshoot. The treat was not discussed.",
                "Nobody told \(name) the zoomies had an off switch.",
                "\(name), professional \(trait), amateur napper.",
                "If I fits, I sits. If I don't, I still sits. — \(name)",
                "\(name) would like to speak to the manager of walks."
            ]
        case .sassy:
            return [
                "\(name) woke up like this. You're welcome.",
                "The couch was free. \(name) improved it.",
                "Don't call it begging. \(name) calls it negotiation.",
                "\(name) is the \(trait) and also the boss.",
                "We can go outside when \(name) says we can go outside."
            ]
        case .wholesome:
            return [
                "\(name) saved a little quiet just for you.",
                "Home is wherever \(name) is leaning.",
                "Some days the whole job is being a \(trait).",
                "\(name) doesn't count the hours. They count the people.",
                "A small life, held carefully. That's \(name)."
            ]
        case .dramatic:
            return [
                "\(name) waited at the door like the last scene of a film.",
                "The bowl was empty. \(name) will be telling this story for years.",
                "One sunbeam. \(name) treated it like destiny.",
                "Do not look away. \(name) is acting.",
                "History will remember this nap. \(name) already does."
            ]
        }
    }
}
