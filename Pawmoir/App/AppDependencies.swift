import Foundation
import SwiftData
import Observation

/// The objects a screen is allowed to ask for. Tests and previews pass their own.
@MainActor
@Observable
final class AppDependencies {
    let modelContainer: ModelContainer
    let entitlements: EntitlementManager
    let onboardingStore: OnboardingStore
    let analytics: any AnalyticsService
    let ai: any AIService
    let printing: any PrintService
    let photos: any PhotoLibraryService
    let notifications: any NotificationScheduling
    let network: NetworkMonitor

    init(
        modelContainer: ModelContainer,
        entitlements: EntitlementManager,
        onboardingStore: OnboardingStore,
        analytics: any AnalyticsService,
        ai: any AIService,
        printing: any PrintService,
        photos: any PhotoLibraryService,
        notifications: any NotificationScheduling,
        network: NetworkMonitor
    ) {
        self.modelContainer = modelContainer
        self.entitlements = entitlements
        self.onboardingStore = onboardingStore
        self.analytics = analytics
        self.ai = ai
        self.printing = printing
        self.photos = photos
        self.notifications = notifications
        self.network = network
    }

    static func live() throws -> AppDependencies {
        let defaults = try launchDefaults()
        let wantsCloud = !LaunchArguments.isUITesting
            && defaults.bool(forKey: "pawmoir.icloud.enabled")
            && defaults.bool(forKey: "pawmoir.entitlement.premium")
        let container = try ModelContainerFactory.make(
            inMemory: LaunchArguments.isUITesting,
            cloudKit: wantsCloud
        )
        if !LaunchArguments.isUITesting {
            LibraryScanCoordinator.register(container: container)
        }
        let photos: any PhotoLibraryService = LaunchArguments.isUITesting
            ? PreviewPhotoLibraryService(status: .notDetermined, imageCount: 0)
            : PhotoKitLibraryService()
        let notifications: any NotificationScheduling = LaunchArguments.isUITesting
            ? PreviewNotificationService(granted: false)
            : SystemNotificationService()
        let dependencies = AppDependencies(
            modelContainer: container,
            entitlements: EntitlementManager(defaults: defaults),
            onboardingStore: OnboardingStore(defaults: defaults),
            analytics: MockAnalyticsService(),
            ai: MockAIService(),
            printing: MockPrintService(),
            photos: photos,
            notifications: notifications,
            network: NetworkMonitor()
        )
        if LaunchArguments.seedsPreviewData {
            let existing = (try? container.mainContext.fetch(FetchDescriptor<Pet>())) ?? []
            if existing.isEmpty {
                PreviewData.seed(in: container.mainContext)
            }
            dependencies.onboardingStore.hasCompleted = true
        }
        if !LaunchArguments.isUITesting {
            dependencies.network.start()
        }
        return dependencies
    }

    static func preview(onboarded: Bool = true, premium: Bool = false, mediaCount: Int = 412) -> AppDependencies {
        let suite = "pawmoir.preview.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            preconditionFailure("Preview settings store was unavailable")
        }
        let container: ModelContainer
        do {
            container = try ModelContainerFactory.make(inMemory: true)
        } catch {
            preconditionFailure("Preview store failed: \(error.localizedDescription)")
        }
        let dependencies = AppDependencies(
            modelContainer: container,
            entitlements: EntitlementManager(defaults: defaults),
            onboardingStore: OnboardingStore(defaults: defaults),
            analytics: MockAnalyticsService(),
            ai: MockAIService(),
            printing: MockPrintService(),
            photos: PreviewPhotoLibraryService(status: .authorized, imageCount: mediaCount),
            notifications: PreviewNotificationService(),
            network: NetworkMonitor()
        )
        if premium {
            dependencies.entitlements.startTrial()
        }
        if onboarded {
            PreviewData.seed(in: container.mainContext)
            dependencies.onboardingStore.hasCompleted = true
        }
        return dependencies
    }

    private static func launchDefaults() throws -> UserDefaults {
        guard LaunchArguments.isUITesting else { return .standard }
        let name = "pawmoir.uitesting"
        guard let suite = UserDefaults(suiteName: name) else {
            throw AppError.persistence("Could not open the test settings store.")
        }
        suite.removePersistentDomain(forName: name)
        return suite
    }
}
