import Foundation

enum AppError: LocalizedError, Equatable {
    case validation(String)
    case persistence(String)
    case unavailable(String)

    var errorDescription: String? {
        switch self {
        case .validation(let message), .persistence(let message), .unavailable(let message):
            message
        }
    }
}
