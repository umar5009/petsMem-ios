import Foundation

final class MockAnalyticsService: AnalyticsService, @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [AnalyticsEvent] = []

    func track(_ event: AnalyticsEvent) {
        lock.lock()
        stored.append(event)
        lock.unlock()
    }

    func snapshot() -> [AnalyticsEvent] {
        lock.lock()
        defer { lock.unlock() }
        return stored
    }
}
