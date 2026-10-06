import SwiftUI
import SwiftData

struct PetsHomeView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Pet.createdAt) private var pets: [Pet]
    @State private var showAdd = false
    @State private var showPaywall = false
    @State private var selectedPlan: PaywallPlan = .yearly

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if pets.isEmpty {
                    EmptyStateView(
                        systemImage: "pawprint",
                        title: "No pets yet",
                        message: "Add the one who greets you at the door.",
                        actionTitle: "Add a pet",
                        action: addTapped
                    )
                } else {
                    ForEach(pets) { pet in
                        NavigationLink(value: pet.id) {
                            petRow(pet)
                        }
                        .buttonStyle(.plain)
                    }
                    PrimaryButton(title: "Add a pet", style: .plain, action: addTapped)
                }
            }
            .padding(20)
        }
        .navigationTitle("Pets")
        .navigationDestination(for: UUID.self) { id in
            if let pet = pets.first(where: { $0.id == id }) {
                PetDetailView(pet: pet)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Settings")
            }
        }
        .background(PawColor.background)
        .sheet(isPresented: $showAdd) {
            AddAnotherPetSheet()
        }
        .sheet(isPresented: $showPaywall) {
            NavigationStack {
                PaywallView(
                    petName: pets.first?.name,
                    allowsSkip: true,
                    selectedPlan: $selectedPlan,
                    onStartTrial: {
                        dependencies.entitlements.startTrial()
                        dependencies.analytics.track(AnalyticsEvent(.trialStarted, properties: ["source": "pet-limit"]))
                        showPaywall = false
                        showAdd = true
                    },
                    onSkip: { showPaywall = false }
                )
            }
        }
    }

    private func petRow(_ pet: Pet) -> some View {
        HStack(spacing: 14) {
            PetAvatar(imageData: pet.avatarJPEG, name: pet.name, species: pet.species, size: 56)
            VStack(alignment: .leading, spacing: 4) {
                Text(pet.name)
                    .font(PawFont.title(.headline))
                    .foregroundStyle(PawColor.textPrimary)
                Text(subtitle(for: pet))
                    .font(PawFont.body(.subheadline))
                    .foregroundStyle(PawColor.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(PawColor.textTertiary)
                .accessibilityHidden(true)
        }
        .padding(12)
        .frame(minHeight: 44)
        .background(PawColor.surfaceElevated, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func subtitle(for pet: Pet) -> String {
        if let age = PetAgeCalculator.age(species: pet.species, birthday: pet.birthday, gotchaDay: pet.gotchaDay) {
            return "\(age.humanSummary) · \(age.petYears) pet years"
        }
        return pet.breed.isEmpty ? pet.species.title : pet.breed
    }

    private func addTapped() {
        if dependencies.entitlements.canAddPet(currentCount: pets.count) {
            showAdd = true
        } else {
            showPaywall = true
        }
    }
}

struct AddAnotherPetSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppDependencies.self) private var dependencies
    @State private var draft = PetDraft()
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                AddPetStep(draft: $draft)
            }
            .background(PawColor.background)
            .navigationTitle("New pet")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(title: "Save pet", isEnabled: draft.isValid) {
                    save()
                }
                .padding()
                .background(PawColor.background)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
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
        }
    }

    private func save() {
        let pet = draft.makePet()
        modelContext.insert(pet)
        do {
            try modelContext.save()
            dependencies.analytics.track(AnalyticsEvent(.petCreated))
            Haptics.success()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
