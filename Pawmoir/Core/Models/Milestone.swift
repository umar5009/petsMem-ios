import Foundation
import SwiftData

/// A marked day on a pet's timeline: coming home, a birthday, a first walk.
@Model
final class Milestone {
    var id: UUID
    var typeRaw: String
    var date: Date
    var title: String
    var note: String

    var pet: Pet?

    init(
        id: UUID = UUID(),
        type: MilestoneType,
        date: Date,
        title: String,
        note: String = "",
        pet: Pet? = nil
    ) {
        self.id = id
        self.typeRaw = type.rawValue
        self.date = date
        self.title = title
        self.note = note
        self.pet = pet
    }

    var type: MilestoneType {
        get { MilestoneType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }
}
