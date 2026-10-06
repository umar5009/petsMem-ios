import Foundation

struct AnalyticsEvent: Sendable, Equatable {
    var name: String
    var properties: [String: String]

    init(_ name: Name, properties: [String: String] = [:]) {
        self.name = name.rawValue
        self.properties = properties
    }

    enum Name: String, Sendable {
        case onboardingStepViewed
        case onboardingCompleted
        case trialStarted
        case paywallSkipped
        case petCreated
        case memoryAdded
        case captionPreviewed
        case captionReported
        case dataExported
        case dataDeleted
    }
}

/// Vendor-neutral analytics. The mock keeps events on device for tests.
protocol AnalyticsService: Sendable {
    func track(_ event: AnalyticsEvent)
}
