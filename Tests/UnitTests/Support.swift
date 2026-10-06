import Foundation
import XCTest
@testable import Pawmoir

@MainActor
final class OnboardingHarness {
    let defaults: UserDefaults
    let suiteName: String
    let entitlements: EntitlementManager
    let store: OnboardingStore
    let analytics: MockAnalyticsService
    let photos: StubPhotoLibrary
    let notifications: StubNotificationScheduler

    init() {
        suiteName = "pawmoir.test.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            preconditionFailure("Test settings store was unavailable")
        }
        defaults.removePersistentDomain(forName: suiteName)
        self.defaults = defaults
        entitlements = EntitlementManager(defaults: defaults)
        store = OnboardingStore(defaults: defaults)
        analytics = MockAnalyticsService()
        photos = StubPhotoLibrary()
        notifications = StubNotificationScheduler()
    }

    func makeModel(step: OnboardingStep? = nil) -> OnboardingViewModel {
        let model = OnboardingViewModel(
            photos: photos,
            notifications: notifications,
            entitlements: entitlements,
            analytics: analytics,
            store: store,
            initialStep: step
        )
        model.tileDelay = .zero
        return model
    }

    func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
    }
}

final class StubPhotoLibrary: PhotoLibraryService, @unchecked Sendable {
    var status: PhotoAuthorization = .notDetermined
    var count = 0

    func authorizationStatus() -> PhotoAuthorization { status }

    func requestAccess() async -> PhotoAuthorization {
        if status == .notDetermined {
            status = .authorized
        }
        return status
    }

    func mediaCount() async -> Int {
        status.canReadLibrary ? count : 0
    }
}

final class StubNotificationScheduler: NotificationScheduling, @unchecked Sendable {
    var requested = false

    func authorizationStatus() async -> NotificationAuthorization { .notDetermined }

    func requestAuthorization() async -> Bool {
        requested = true
        return true
    }
}

enum TestDefaults {
    static func fresh() -> (UserDefaults, String) {
        let name = "pawmoir.test.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: name) else {
            preconditionFailure("Test settings store was unavailable")
        }
        defaults.removePersistentDomain(forName: name)
        return (defaults, name)
    }
}
