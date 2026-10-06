import Foundation

/// Dog, cat, or anything else the family counts as a pet.
enum PetSpecies: String, Codable, CaseIterable, Identifiable, Sendable {
    case dog
    case cat
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dog: "Dog"
        case .cat: "Cat"
        case .other: "Other"
        }
    }

    var symbolName: String {
        switch self {
        case .dog: "dog.fill"
        case .cat: "cat.fill"
        case .other: "pawprint.fill"
        }
    }
}

/// How a memory felt. Stored as a raw string so the diary can gain moods later.
enum Mood: String, Codable, CaseIterable, Identifiable, Sendable {
    case happy
    case playful
    case sleepy
    case cuddly
    case adventurous
    case hungry
    case proud
    case calm

    var id: String { rawValue }

    var title: String {
        switch self {
        case .happy: "Happy"
        case .playful: "Playful"
        case .sleepy: "Sleepy"
        case .cuddly: "Cuddly"
        case .adventurous: "Adventurous"
        case .hungry: "Hungry"
        case .proud: "Proud"
        case .calm: "Calm"
        }
    }

    var symbolName: String {
        switch self {
        case .happy: "sun.max.fill"
        case .playful: "figure.play"
        case .sleepy: "moon.fill"
        case .cuddly: "heart.fill"
        case .adventurous: "map.fill"
        case .hungry: "fork.knife"
        case .proud: "star.fill"
        case .calm: "leaf.fill"
        }
    }
}

enum MilestoneType: String, Codable, CaseIterable, Identifiable, Sendable {
    case firstDayHome
    case firstWalk
    case birthday
    case gotchaDay
    case achievement
    case other

    var id: String { rawValue }

    var defaultTitle: String {
        switch self {
        case .firstDayHome: "First day home"
        case .firstWalk: "First walk"
        case .birthday: "Birthday"
        case .gotchaDay: "Gotcha day"
        case .achievement: "Achievement"
        case .other: "Milestone"
        }
    }
}

enum CreationType: String, Codable, CaseIterable, Identifiable, Sendable {
    case caption
    case video
    case recap
    case collage

    var id: String { rawValue }
}

enum PrintProductType: String, Codable, CaseIterable, Identifiable, Sendable {
    case hardcoverBook
    case softcoverBook
    case canvas
    case calendar
    case cardPack

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hardcoverBook: "Hardcover photo book"
        case .softcoverBook: "Softcover book"
        case .canvas: "Canvas print"
        case .calendar: "Wall calendar"
        case .cardPack: "Card pack"
        }
    }

    var blurb: String {
        switch self {
        case .hardcoverBook: "A year of them, bound to keep."
        case .softcoverBook: "Lighter in the hand, just as full."
        case .canvas: "One photograph, big enough for the wall."
        case .calendar: "Twelve months, twelve favorite faces."
        case .cardPack: "Notes and photos you can hand to someone."
        }
    }

    var symbolName: String {
        switch self {
        case .hardcoverBook: "book.closed.fill"
        case .softcoverBook: "book.fill"
        case .canvas: "photo.fill"
        case .calendar: "calendar"
        case .cardPack: "rectangle.stack.fill"
        }
    }

    /// List price in US dollars before the Premium print discount.
    /// StoreKit and the print vendor will own regional prices later.
    var listPriceUSD: Decimal {
        switch self {
        case .hardcoverBook: 39
        case .softcoverBook: 24
        case .canvas: 49
        case .calendar: 29
        case .cardPack: 18
        }
    }
}

enum PrintOrderStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case draft
    case received
    case printing
    case shipped
    case delivered
    case cancelled

    var id: String { rawValue }
}

/// Tone for "what my pet is thinking" captions.
enum CaptionTone: String, Codable, CaseIterable, Identifiable, Sendable {
    case funny
    case sassy
    case wholesome
    case dramatic

    var id: String { rawValue }

    var title: String {
        switch self {
        case .funny: "Funny"
        case .sassy: "Sassy"
        case .wholesome: "Wholesome"
        case .dramatic: "Dramatic"
        }
    }
}

enum PaywallPlan: String, Codable, CaseIterable, Identifiable, Sendable {
    case yearly
    case monthly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .yearly: "Yearly"
        case .monthly: "Monthly"
        }
    }

    var price: String {
        switch self {
        case .yearly: "$34.99/year"
        case .monthly: "$4.99/month"
        }
    }

    var detail: String {
        switch self {
        case .yearly: "7 days free, then $34.99 per year"
        case .monthly: "7 days free, then $4.99 per month"
        }
    }

    var isBestValue: Bool { self == .yearly }

    var productID: String {
        switch self {
        case .yearly: "com.pawmoir.app.premium.yearly"
        case .monthly: "com.pawmoir.app.premium.monthly"
        }
    }
}
