import Foundation

enum PhotoAuthorization: String, Sendable, Equatable {
    case notDetermined
    case restricted
    case denied
    case authorized
    case limited

    var canReadLibrary: Bool {
        self == .authorized || self == .limited
    }
}

/// Photo access for onboarding. Scanning and thumbnail caches come later.
/// Implementations must not copy the user's library.
protocol PhotoLibraryService: Sendable {
    func authorizationStatus() -> PhotoAuthorization
    func requestAccess() async -> PhotoAuthorization
    /// Count of photos and videos the user has allowed us to see. Metadata only.
    func mediaCount() async -> Int
}
