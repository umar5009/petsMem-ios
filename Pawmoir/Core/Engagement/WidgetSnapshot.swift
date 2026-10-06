import Foundation

/// The one card the home screen widget reads. Written by the app, not by PhotoKit.
struct WidgetSnapshot: Codable, Equatable, Sendable {
    var petName: String
    var ageText: String
    var note: String
    var photoJPEG: Data?

    static let placeholder = WidgetSnapshot(
        petName: "Your pet",
        ageText: "Open Pawmoir",
        note: "On this day will show a photo here.",
        photoJPEG: nil
    )
}

enum WidgetSnapshotStore {
    static let fileName = "widget-snapshot.json"
    static let appGroup = "group.com.pawmoir.app"

    static func fileURL() -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
            .appendingPathComponent(fileName)
    }

    static func save(_ snapshot: WidgetSnapshot) {
        guard let url = fileURL(), let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func load() -> WidgetSnapshot? {
        guard let url = fileURL(), let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }
}
