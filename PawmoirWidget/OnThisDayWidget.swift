import SwiftUI
import WidgetKit

struct WidgetSnapshot: Codable, Equatable {
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

    static func load() -> WidgetSnapshot? {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
            .appendingPathComponent(fileName),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }
}

struct OnThisDayEntry: TimelineEntry {
    var date: Date
    var snapshot: WidgetSnapshot
}

struct OnThisDayProvider: TimelineProvider {
    func placeholder(in context: Context) -> OnThisDayEntry {
        OnThisDayEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (OnThisDayEntry) -> Void) {
        completion(OnThisDayEntry(date: .now, snapshot: WidgetSnapshotStore.load() ?? .placeholder))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<OnThisDayEntry>) -> Void) {
        let entry = OnThisDayEntry(date: .now, snapshot: WidgetSnapshotStore.load() ?? .placeholder)
        let next = Calendar.current.date(byAdding: .hour, value: 6, to: .now) ?? Date.now.addingTimeInterval(6 * 3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct OnThisDayWidgetView: View {
    var entry: OnThisDayEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("On this day")
                .font(.caption.weight(.semibold))
            Text(entry.snapshot.petName)
                .font(.headline)
            Text(entry.snapshot.ageText)
                .font(.caption)
            Text(entry.snapshot.note)
                .font(.caption2)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            Color(red: 0.98, green: 0.95, blue: 0.91)
        }
    }
}

struct OnThisDayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "com.pawmoir.app.on-this-day", provider: OnThisDayProvider()) { entry in
            OnThisDayWidgetView(entry: entry)
        }
        .configurationDisplayName("On this day")
        .description("A photo and a note from another year.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct PawmoirWidgetBundle: WidgetBundle {
    var body: some Widget {
        OnThisDayWidget()
    }
}
