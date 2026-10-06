import Foundation

struct PlannedNotification: Equatable, Sendable, Identifiable {
    var id: String
    var title: String
    var body: String
    var date: Date
    var isPlayful: Bool
}

/// At most three reminders in a week. Memorial pets never get playful copy.
enum NotificationPlanner {
    static let weeklyCap = 3

    static func plan(
        pets: [(name: String, birthday: Date?, gotcha: Date?, isMemorial: Bool)],
        now: Date,
        calendar: Calendar = .current,
        alreadyThisWeek: Int
    ) -> [PlannedNotification] {
        let room = max(0, weeklyCap - alreadyThisWeek)
        guard room > 0 else { return [] }
        var planned: [PlannedNotification] = []
        for pet in pets {
            if let anniversary = nextAnniversary(birthday: pet.birthday, gotcha: pet.gotcha, now: now, calendar: calendar) {
                let dayBefore = calendar.date(byAdding: .day, value: -1, to: anniversary) ?? anniversary
                let memorial = pet.isMemorial
                planned.append(
                    PlannedNotification(
                        id: "anniversary-\(pet.name)-\(dayBefore.timeIntervalSince1970)",
                        title: memorial ? "Thinking of \(pet.name)" : "\(pet.name)'s day is tomorrow",
                        body: memorial
                            ? "A quiet page is here whenever you want it."
                            : "Their film will be ready in the morning.",
                        date: morning(of: dayBefore, calendar: calendar),
                        isPlayful: !memorial
                    )
                )
            }
        }
        if let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: calendar.date(byAdding: .month, value: 1, to: now) ?? now)) {
            let living = pets.filter { !$0.isMemorial }
            if let name = living.first?.name {
                planned.append(
                    PlannedNotification(
                        id: "recap-\(monthStart.timeIntervalSince1970)",
                        title: "\(name)'s month is ready",
                        body: "A short recap is waiting in Create.",
                        date: morning(of: monthStart, calendar: calendar),
                        isPlayful: true
                    )
                )
            }
        }
        return Array(planned.sorted { $0.date < $1.date }.prefix(room))
    }

    private static func nextAnniversary(birthday: Date?, gotcha: Date?, now: Date, calendar: Calendar) -> Date? {
        let anchor = birthday ?? gotcha
        guard let anchor else { return nil }
        let parts = calendar.dateComponents([.month, .day], from: anchor)
        var nextParts = calendar.dateComponents([.year], from: now)
        nextParts.month = parts.month
        nextParts.day = parts.day
        guard var next = calendar.date(from: nextParts) else { return nil }
        if next < calendar.startOfDay(for: now) {
            next = calendar.date(byAdding: .year, value: 1, to: next) ?? next
        }
        return next
    }

    private static func morning(of date: Date, calendar: Calendar) -> Date {
        calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
    }
}
