import Foundation
import UserNotifications

enum NotificationAuthorization: Sendable, Equatable {
    case notDetermined
    case denied
    case authorized
}

protocol NotificationScheduling: Sendable {
    func authorizationStatus() async -> NotificationAuthorization
    func requestAuthorization() async -> Bool
    func replacePending(_ items: [PlannedNotification]) async
}

extension NotificationScheduling {
    func replacePending(_ items: [PlannedNotification]) async {}
}

final class SystemNotificationService: NotificationScheduling, @unchecked Sendable {
    func authorizationStatus() async -> NotificationAuthorization {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized, .provisional, .ephemeral:
            return .authorized
        @unknown default:
            return .denied
        }
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func replacePending(_ items: [PlannedNotification]) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let ours = pending.map(\.identifier).filter { $0.hasPrefix("pawmoir.") }
        center.removePendingNotificationRequests(withIdentifiers: ours)
        for item in items.prefix(NotificationPlanner.weeklyCap) {
            let content = UNMutableNotificationContent()
            content.title = item.title
            content.body = item.body
            content.sound = .default
            let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: item.date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            let request = UNNotificationRequest(identifier: "pawmoir.\(item.id)", content: content, trigger: trigger)
            try? await center.add(request)
        }
    }
}

/// Used by previews and UI tests so the system prompt never appears.
final class PreviewNotificationService: NotificationScheduling, @unchecked Sendable {
    var granted: Bool

    init(granted: Bool = true) {
        self.granted = granted
    }

    func authorizationStatus() async -> NotificationAuthorization {
        granted ? .authorized : .notDetermined
    }

    func requestAuthorization() async -> Bool {
        granted = true
        return true
    }
}
