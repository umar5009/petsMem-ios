import Foundation

enum ExportAspect: String, CaseIterable, Identifiable, Sendable {
    case story
    case square
    case landscape

    var id: String { rawValue }

    var title: String {
        switch self {
        case .story: "Story 9:16"
        case .square: "Post 1:1"
        case .landscape: "Wide 16:9"
        }
    }

    var pixelSize: CGSize {
        switch self {
        case .story: CGSize(width: 1080, height: 1920)
        case .square: CGSize(width: 1080, height: 1080)
        case .landscape: CGSize(width: 1920, height: 1080)
        }
    }
}

enum ExportPolicy {
    static let watermarkText = "Made with Pawmoir"

    static func includesWatermark(isPremium: Bool) -> Bool {
        !isPremium
    }
}

struct MusicTrack: Identifiable, Equatable, Sendable {
    var id: String
    var title: String
    var isPremium: Bool
    /// Base frequency for the original tone generated in the app. Not a licensed recording.
    var frequency: Double

    static let library: [MusicTrack] = [
        MusicTrack(id: "soft", title: "Soft light", isPremium: false, frequency: 220),
        MusicTrack(id: "warm", title: "Warm room", isPremium: false, frequency: 262),
        MusicTrack(id: "playful", title: "Little steps", isPremium: false, frequency: 330),
        MusicTrack(id: "bright", title: "Open window", isPremium: true, frequency: 392),
        MusicTrack(id: "calm", title: "Slow afternoon", isPremium: true, frequency: 196),
        MusicTrack(id: "night", title: "Quiet house", isPremium: true, frequency: 174)
    ]

    static func available(isPremium: Bool) -> [MusicTrack] {
        isPremium ? library : library.filter { !$0.isPremium }
    }
}

enum StudioTemplateLibrary {
    static let all: [StudioTemplate] = [
        StudioTemplate(id: "polaroid", title: "Polaroid", symbol: "photo", isPremium: false),
        StudioTemplate(id: "caption", title: "Caption card", symbol: "text.bubble", isPremium: false),
        StudioTemplate(id: "then-now", title: "Then & now", symbol: "square.split.2x1", isPremium: false),
        StudioTemplate(id: "magazine", title: "Magazine", symbol: "newspaper", isPremium: false),
        StudioTemplate(id: "film", title: "Film strip", symbol: "film", isPremium: false),
        StudioTemplate(id: "comic", title: "Comic", symbol: "bubble.left.and.bubble.right", isPremium: true),
        StudioTemplate(id: "card", title: "Trading card", symbol: "rectangle.portrait", isPremium: true),
        StudioTemplate(id: "birthday", title: "Birthday", symbol: "gift", isPremium: true),
        StudioTemplate(id: "grid", title: "Four up", symbol: "square.grid.2x2", isPremium: true),
        StudioTemplate(id: "story", title: "Story frame", symbol: "rectangle.portrait", isPremium: true),
        StudioTemplate(id: "scrapbook", title: "Scrapbook", symbol: "book", isPremium: true),
        StudioTemplate(id: "quote", title: "Quote", symbol: "quote.opening", isPremium: true),
        StudioTemplate(id: "yearbook", title: "Yearbook", symbol: "text.book.closed", isPremium: true),
        StudioTemplate(id: "memorial", title: "In loving memory", symbol: "heart", isPremium: false),
        StudioTemplate(id: "duo", title: "Side by side", symbol: "rectangle.split.2x1", isPremium: true),
        StudioTemplate(id: "sticker", title: "Sticker", symbol: "seal", isPremium: true),
        StudioTemplate(id: "postcard", title: "Postcard", symbol: "envelope", isPremium: true),
        StudioTemplate(id: "month", title: "Month page", symbol: "calendar", isPremium: true),
        StudioTemplate(id: "strip", title: "Photo strip", symbol: "film.stack", isPremium: true),
        StudioTemplate(id: "cover", title: "Cover", symbol: "magazine", isPremium: true)
    ]
}
