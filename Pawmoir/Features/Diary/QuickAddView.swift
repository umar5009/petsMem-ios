import SwiftUI
import SwiftData

@MainActor
@Observable
final class QuickAddViewModel {
    var note = ""
    var mood: Mood = .happy
    var date = Date.now
    var location = ""

    func save(pet: Pet, context: ModelContext) throws {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AppError.validation("Write a note to save this memory.")
        }
        let place = location.trimmingCharacters(in: .whitespacesAndNewlines)
        let entry = MemoryEntry(
            date: date,
            note: trimmed,
            mood: mood,
            locationName: place.isEmpty ? nil : place,
            pets: [pet]
        )
        context.insert(entry)
        try context.save()
    }
}

struct QuickAddView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppDependencies.self) private var dependencies
    @Query(sort: \Pet.createdAt) private var pets: [Pet]
    @State private var model = QuickAddViewModel()
    @State private var petID: UUID?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if pets.isEmpty {
                        Text("Add a pet before writing a memory.")
                            .font(PawFont.body())
                            .foregroundStyle(PawColor.textSecondary)
                    } else {
                        if pets.count > 1 {
                            petPicker
                        }
                        TextField("What happened?", text: $model.note, axis: .vertical)
                            .lineLimit(4...8)
                            .font(PawFont.body())
                            .padding(14)
                            .background(PawColor.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        DatePicker("Date", selection: $model.date, in: ...Date.now, displayedComponents: .date)
                        TextField("Place, if you want", text: $model.location)
                            .padding(14)
                            .background(PawColor.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        FlowLayout(spacing: 8) {
                            ForEach(Mood.allCases) { mood in
                                SelectableChip(title: mood.title, isSelected: model.mood == mood) {
                                    model.mood = mood
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(PawColor.background)
            .navigationTitle("New memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(pets.isEmpty)
                }
            }
            .alert("Couldn't save", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .onAppear {
                if petID == nil {
                    petID = pets.first?.id
                }
            }
        }
    }

    private var petPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(pets) { pet in
                    SelectableChip(title: pet.name, isSelected: petID == pet.id) {
                        petID = pet.id
                    }
                }
            }
        }
    }

    private func save() {
        guard let pet = pets.first(where: { $0.id == petID }) ?? pets.first else { return }
        do {
            try model.save(pet: pet, context: modelContext)
            dependencies.analytics.track(AnalyticsEvent(.memoryAdded))
            Haptics.success()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
