import SwiftUI
import SwiftData

struct PetDetailView: View {
    @Bindable var pet: Pet
    @Environment(\.modelContext) private var modelContext
    @Environment(AppDependencies.self) private var dependencies
    @State private var newFavorite = ""
    @State private var milestoneTitle = ""
    @State private var milestoneDate = Date.now
    @State private var weightText = ""
    @State private var confirmMemorial = false
    @State private var familyName = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(spacing: 16) {
                    PetAvatar(imageData: pet.avatarJPEG, name: pet.name, species: pet.species, size: 88)
                    VStack(alignment: .leading, spacing: 6) {
                        TextField("Name", text: $pet.name)
                            .font(PawFont.display(.title))
                            .foregroundStyle(PawColor.textPrimary)
                        Text(pet.breed.isEmpty ? pet.species.title : "\(pet.species.title) · \(pet.breed)")
                            .font(PawFont.body())
                            .foregroundStyle(PawColor.textSecondary)
                    }
                }

                if let age = PetAgeCalculator.age(species: pet.species, birthday: pet.birthday, gotchaDay: pet.gotchaDay) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(age.humanSummary)
                            .font(PawFont.title())
                        Text("\(age.petYears) pet years · counted from their \(age.basis == .birthday ? "birthday" : "gotcha day")")
                            .font(PawFont.body(.subheadline))
                            .foregroundStyle(PawColor.textSecondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(PawColor.coralSoft, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                if pet.isMemorial {
                    Text("In loving memory")
                        .font(PawFont.title(.headline))
                        .foregroundStyle(PawColor.textPrimary)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(PawColor.sageSoft, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    Text("Playful captions and reminders stay off. Nothing here asks you to subscribe.")
                        .font(PawFont.body(.subheadline))
                        .foregroundStyle(PawColor.textSecondary)
                } else {
                    Button("Turn on Remembrance") {
                        confirmMemorial = true
                    }
                    .frame(minHeight: 44)
                }

                sectionTitle("Family")
                if dependencies.entitlements.isPremium {
                    if pet.shareCode.isEmpty {
                        Button("Create an invite code") {
                            pet.shareCode = FamilySharing.makeCode(for: pet.name)
                            try? modelContext.save()
                        }
                        .frame(minHeight: 44)
                    } else {
                        Text(pet.shareCode)
                            .font(PawFont.title())
                        Text("Someone on Premium can type this code on their iPhone. Sharing stays on this device until iCloud sync is on.")
                            .font(PawFont.body(.footnote))
                            .foregroundStyle(PawColor.textSecondary)
                    }
                    ForEach(pet.familyMemberNames, id: \.self) { name in
                        Text(name)
                            .font(PawFont.body())
                    }
                    HStack {
                        TextField("Family member", text: $familyName)
                            .padding(12)
                            .background(PawColor.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        Button("Add") {
                            let trimmed = familyName.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            pet.familyMemberNames.append(trimmed)
                            familyName = ""
                            try? modelContext.save()
                        }
                        .frame(minWidth: 44, minHeight: 44)
                    }
                } else if pet.isMemorial {
                    Text("Family sharing can wait.")
                        .font(PawFont.body(.subheadline))
                        .foregroundStyle(PawColor.textSecondary)
                } else {
                    Text("Family sharing is part of Premium.")
                        .font(PawFont.body(.subheadline))
                        .foregroundStyle(PawColor.textSecondary)
                }

                sectionTitle("Personality")
                FlowLayout(spacing: 8) {
                    ForEach(PersonalityCatalog.suggestions, id: \.self) { tag in
                        SelectableChip(title: tag, isSelected: pet.personalityTags.contains(tag)) {
                            toggleTag(tag)
                        }
                    }
                }

                sectionTitle("Favorite things")
                FlowLayout(spacing: 8) {
                    ForEach(pet.favoriteThings, id: \.self) { thing in
                        SelectableChip(title: thing, isSelected: true) {
                            pet.favoriteThings.removeAll { $0 == thing }
                        }
                    }
                    ForEach(FavoriteSuggestions.all.filter { !pet.favoriteThings.contains($0) }, id: \.self) { thing in
                        SelectableChip(title: thing, isSelected: false) {
                            pet.favoriteThings.append(thing)
                        }
                    }
                }
                HStack {
                    TextField("Add one", text: $newFavorite)
                        .padding(12)
                        .background(PawColor.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    Button("Add") { addFavorite() }
                        .frame(minWidth: 44, minHeight: 44)
                }

                sectionTitle("Weight")
                TextField("Kilograms", text: $weightText)
                    .keyboardType(.decimalPad)
                    .padding(12)
                    .background(PawColor.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .onSubmit(saveWeight)
                if let kg = pet.weightKilograms {
                    Text(weightLabel(kg))
                        .font(PawFont.body(.footnote))
                        .foregroundStyle(PawColor.textSecondary)
                }
                Button("Save weight") { saveWeight() }
                    .frame(minHeight: 44)

                sectionTitle("Milestones")
                if pet.milestones.isEmpty {
                    Text("Birthdays, coming home, the first walk.")
                        .font(PawFont.body(.subheadline))
                        .foregroundStyle(PawColor.textSecondary)
                } else {
                    ForEach(pet.milestones.sorted(by: { $0.date < $1.date })) { milestone in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(milestone.title)
                                .font(PawFont.title(.headline))
                            Text(milestone.date, format: .dateTime.month(.wide).day().year())
                                .font(PawFont.body(.subheadline))
                                .foregroundStyle(PawColor.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(PawColor.surfaceElevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                TextField("Milestone title", text: $milestoneTitle)
                    .padding(12)
                    .background(PawColor.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                DatePicker("Date", selection: $milestoneDate, in: ...Date.now, displayedComponents: .date)
                Button("Add milestone") { addMilestone() }
                    .frame(minHeight: 44)
                    .disabled(milestoneTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(20)
        }
        .navigationTitle(pet.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(PawColor.background)
        .confirmationDialog(
            "Turn on Remembrance for \(pet.name)?",
            isPresented: $confirmMemorial,
            titleVisibility: .visible
        ) {
            Button("Turn on Remembrance") {
                pet.isMemorial = true
                try? modelContext.save()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The diary stays. Captions and reminders become quiet. You can leave this on.")
        }
        .onAppear {
            if let kg = pet.weightKilograms {
                weightText = String(kg)
            }
        }
    }

    private func sectionTitle(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(PawFont.title(.headline))
            .foregroundStyle(PawColor.textPrimary)
            .padding(.top, 4)
    }

    private func toggleTag(_ tag: String) {
        if let index = pet.personalityTags.firstIndex(of: tag) {
            pet.personalityTags.remove(at: index)
        } else {
            pet.personalityTags.append(tag)
        }
    }

    private func addFavorite() {
        let trimmed = newFavorite.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !pet.favoriteThings.contains(trimmed) else { return }
        pet.favoriteThings.append(trimmed)
        newFavorite = ""
    }

    private func saveWeight() {
        let normalized = weightText.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value > 0, value < 200 else { return }
        pet.weightKilograms = value
        try? modelContext.save()
    }

    private func weightLabel(_ kilograms: Double) -> String {
        let measurement = Measurement(value: kilograms, unit: UnitMass.kilograms)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        formatter.unitStyle = .short
        return formatter.string(from: measurement)
    }

    private func addMilestone() {
        let title = milestoneTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let milestone = Milestone(type: .other, date: milestoneDate, title: title, pet: pet)
        modelContext.insert(milestone)
        try? modelContext.save()
        milestoneTitle = ""
    }
}
