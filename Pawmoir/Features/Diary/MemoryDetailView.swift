import SwiftUI
import SwiftData

struct MemoryDetailView: View {
    @Bindable var memory: MemoryEntry
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Pet.createdAt) private var pets: [Pet]
    @State private var note: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let asset = memory.assetLocalIdentifier {
                    AssetThumbnail(localIdentifier: asset, side: 320)
                        .frame(maxWidth: .infinity)
                        .frame(height: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .accessibilityLabel("Diary photo")
                }
                Text(memory.date.formatted(date: .abbreviated, time: .omitted))
                    .font(PawFont.body(.subheadline))
                    .foregroundStyle(PawColor.textSecondary)
                if memory.needsConfirmation {
                    Text("Who is this?")
                        .font(PawFont.title())
                    HStack {
                        ForEach(pets) { pet in
                            SelectableChip(title: pet.name, isSelected: memory.pets.contains(where: { $0.id == pet.id })) {
                                memory.pets = [pet]
                                memory.needsConfirmation = false
                                try? modelContext.save()
                            }
                        }
                    }
                }
                TextField("Add a note", text: $note, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(PawColor.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                TextField("Place", text: Binding(
                    get: { memory.locationName ?? "" },
                    set: { memory.locationName = $0.isEmpty ? nil : $0 }
                ))
                .padding(12)
                .background(PawColor.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                FlowLayout(spacing: 8) {
                    ForEach(Mood.allCases) { mood in
                        SelectableChip(title: mood.title, isSelected: memory.mood == mood) {
                            memory.mood = mood
                        }
                    }
                }
                Toggle("Favorite", isOn: $memory.isFavorite)
                    .tint(PawColor.primary)
                Button("Save note") {
                    memory.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
                    try? modelContext.save()
                    Haptics.success()
                }
                .frame(minHeight: 44)
            }
            .padding(20)
        }
        .navigationTitle("Memory")
        .navigationBarTitleDisplayMode(.inline)
        .background(PawColor.background)
        .onAppear { note = memory.note }
    }
}
