import Foundation

/// Letter in the US and Canada, A4 elsewhere. Print layouts will use this later.
enum PaperStandard {
    static func preferred(locale: Locale = .current) -> String {
        switch locale.region?.identifier {
        case "US", "CA":
            "Letter"
        default:
            "A4"
        }
    }
}
