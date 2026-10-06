import Foundation
import SwiftData

@MainActor
enum PreviewData {
    static func seed(in context: ModelContext) {
        let calendar = Calendar.current
        let birthday = calendar.date(byAdding: .year, value: -2, to: .now) ?? .now
        let pet = Pet(
            name: "Bella",
            species: .dog,
            breed: "Golden Retriever",
            birthday: birthday,
            personalityTags: ["Drama queen", "Nap champion"],
            favoriteThings: ["Walks", "Sunbeams"]
        )
        let milestone = Milestone(type: .birthday, date: birthday, title: "Birthday", pet: pet)
        let memory = MemoryEntry(
            date: .now,
            note: "She waited by the door like the walk was a ceremony.",
            mood: .proud,
            locationName: "Home",
            pets: [pet]
        )
        context.insert(pet)
        context.insert(milestone)
        context.insert(memory)
        try? context.save()
    }
}
