import SwiftUI
import PhotosUI

struct WelcomeStep: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 12)
            ZStack {
                Circle()
                    .fill(PawColor.coralSoft)
                    .frame(width: 220, height: 220)
                    .scaleEffect(appeared || reduceMotion ? 1 : 0.9)
                Circle()
                    .fill(PawColor.primary.opacity(0.16))
                    .frame(width: 150, height: 150)
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(PawColor.primary)
                    .rotationEffect(.degrees(-18))
                    .accessibilityHidden(true)
                decorativePaw(x: -90, y: -70, size: 22, delay: 0.05)
                decorativePaw(x: 96, y: -40, size: 16, delay: 0.12)
                decorativePaw(x: 80, y: 90, size: 18, delay: 0.18)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Pawmoir")

            VStack(spacing: 12) {
                Text("Pawmoir")
                    .font(PawFont.display())
                    .foregroundStyle(PawColor.textPrimary)
                Text("Every pawprint deserves to be remembered")
                    .font(PawFont.body(.title3))
                    .foregroundStyle(PawColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("onboarding.welcome.tagline")
            }
            Spacer(minLength: 12)
        }
        .padding(.horizontal, 28)
        .onAppear {
            guard !reduceMotion else {
                appeared = true
                return
            }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.72)) {
                appeared = true
            }
        }
    }

    private func decorativePaw(x: CGFloat, y: CGFloat, size: CGFloat, delay: Double) -> some View {
        Image(systemName: "pawprint.fill")
            .font(.system(size: size))
            .foregroundStyle(PawColor.secondary.opacity(0.85))
            .offset(x: x, y: y)
            .opacity(appeared || reduceMotion ? 1 : 0)
            .animation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.7).delay(delay), value: appeared)
            .accessibilityHidden(true)
    }
}

struct AddPetStep: View {
    @Binding var draft: PetDraft
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Who's the star?")
                    .font(PawFont.display(.title))
                    .foregroundStyle(PawColor.textPrimary)
                Text("A name is enough. The rest can wait.")
                    .font(PawFont.body())
                    .foregroundStyle(PawColor.textSecondary)
            }

            HStack {
                Spacer()
                PhotosPicker(selection: $photoItem, matching: .images) {
                    PetAvatar(imageData: draft.avatarJPEG, name: draft.name, species: draft.species, size: 96)
                }
                .accessibilityLabel("Add a profile photo")
                Spacer()
            }
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task { await loadPhoto(item) }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(PawFont.body(.subheadline, weight: .semibold))
                    .foregroundStyle(PawColor.textSecondary)
                TextField("Bella", text: $draft.name)
                    .font(PawFont.title(.title3))
                    .textInputAutocapitalization(.words)
                    .padding(14)
                    .background(PawColor.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(PawColor.separator, lineWidth: 1)
                    )
                    .accessibilityIdentifier("onboarding.pet.name")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Species")
                    .font(PawFont.body(.subheadline, weight: .semibold))
                    .foregroundStyle(PawColor.textSecondary)
                HStack(spacing: 8) {
                    ForEach(PetSpecies.allCases) { species in
                        SelectableChip(title: species.title, isSelected: draft.species == species) {
                            draft.species = species
                            draft.breed = ""
                        }
                    }
                }
            }

            breedField

            VStack(alignment: .leading, spacing: 8) {
                Text("The day that matters")
                    .font(PawFont.body(.subheadline, weight: .semibold))
                    .foregroundStyle(PawColor.textSecondary)
                HStack(spacing: 8) {
                    SelectableChip(title: "Birthday", isSelected: !draft.usesGotchaDay && draft.hasDate) {
                        draft.usesGotchaDay = false
                        draft.hasDate = true
                    }
                    SelectableChip(title: "Gotcha day", isSelected: draft.usesGotchaDay && draft.hasDate) {
                        draft.usesGotchaDay = true
                        draft.hasDate = true
                    }
                    SelectableChip(title: "Not sure", isSelected: !draft.hasDate) {
                        draft.hasDate = false
                    }
                }
                if draft.hasDate {
                    DatePicker(
                        draft.usesGotchaDay ? "Gotcha day" : "Birthday",
                        selection: $draft.date,
                        in: ...Date.now,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .font(PawFont.body())
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Personality")
                    .font(PawFont.body(.subheadline, weight: .semibold))
                    .foregroundStyle(PawColor.textSecondary)
                Text("Optional. It helps captions sound like them.")
                    .font(PawFont.body(.footnote))
                    .foregroundStyle(PawColor.textTertiary)
                FlowLayout(spacing: 8) {
                    ForEach(PersonalityCatalog.suggestions, id: \.self) { tag in
                        SelectableChip(title: tag, isSelected: draft.personalityTags.contains(tag)) {
                            toggle(tag)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }

    private var breedField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Breed")
                .font(PawFont.body(.subheadline, weight: .semibold))
                .foregroundStyle(PawColor.textSecondary)
            TextField("Search breeds", text: $draft.breed)
                .textInputAutocapitalization(.words)
                .padding(14)
                .background(PawColor.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(PawColor.separator, lineWidth: 1)
                )
            let suggestions = BreedCatalog.suggestions(for: draft.species, query: draft.breed)
            if !suggestions.isEmpty, draft.breed != suggestions.first {
                FlowLayout(spacing: 8) {
                    ForEach(suggestions, id: \.self) { breed in
                        SelectableChip(title: breed, isSelected: draft.breed == breed) {
                            draft.breed = breed
                        }
                    }
                }
            }
        }
    }

    private func toggle(_ tag: String) {
        if let index = draft.personalityTags.firstIndex(of: tag) {
            draft.personalityTags.remove(at: index)
        } else {
            draft.personalityTags.append(tag)
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else { return }
            let thumbnail = await ImageSizing.jpegThumbnail(from: data)
            draft.avatarJPEG = thumbnail ?? data
        } catch {
            draft.avatarJPEG = nil
        }
    }
}

struct PhotoAccessStep: View {
    var petName: String
    var authorization: PhotoAuthorization
    var onManageLimited: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(PawColor.primary)
                .frame(width: 84, height: 84)
                .background(PawColor.coralSoft, in: Circle())
                .accessibilityHidden(true)

            Text("Find \(petName) in your photos")
                .font(PawFont.display(.title))
                .foregroundStyle(PawColor.textPrimary)
            Text("Pawmoir looks on this iPhone only. Your library is not uploaded. You can share a few photos, or the whole library, and change that anytime.")
                .font(PawFont.body())
                .foregroundStyle(PawColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if authorization == .limited {
                Text("Limited access is on. Only the photos you picked can be used.")
                    .font(PawFont.body(.subheadline))
                    .foregroundStyle(PawColor.textPrimary)
                Button("Choose more photos", action: onManageLimited)
                    .font(PawFont.body(.body, weight: .semibold))
                    .frame(minHeight: 44)
            } else if authorization == .denied || authorization == .restricted {
                Text("Photo access is off. You can turn it on in Settings, or add memories yourself.")
                    .font(PawFont.body(.subheadline))
                    .foregroundStyle(PawColor.textPrimary)
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MagicMomentStep: View {
    var petName: String
    var mediaCount: Int
    var revealedTiles: Int
    var isReady: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let columns = [GridItem(.adaptive(minimum: 72), spacing: 8)]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("A first look")
                .font(PawFont.body(.subheadline, weight: .semibold))
                .foregroundStyle(PawColor.secondary)
            if !isReady {
                LoadingShimmer(height: 72)
                LoadingShimmer()
            } else if mediaCount > 0 {
                Text(mediaCount, format: .number)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(PawColor.textPrimary)
                    .contentTransition(.numericText())
                    .accessibilityLabel("\(mediaCount) photos and videos")
                Text("photos and videos on this iPhone, ready for \(petName). Matching them happens on device. Nothing is uploaded.")
                    .font(PawFont.body())
                    .foregroundStyle(PawColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(0..<revealedTiles, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(tileColor(index))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundStyle(PawColor.onPrimary.opacity(0.8))
                            }
                            .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                            .accessibilityHidden(true)
                    }
                }
                .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8), value: revealedTiles)
            } else {
                Text("\(petName)'s album is a blank page")
                    .font(PawFont.display(.title))
                    .foregroundStyle(PawColor.textPrimary)
                Text("There aren't photos to look through yet. The next one you take, or a note you add, starts the diary.")
                    .font(PawFont.body())
                    .foregroundStyle(PawColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func tileColor(_ index: Int) -> Color {
        switch index % 3 {
        case 0: PawColor.primary.opacity(0.85)
        case 1: PawColor.secondary.opacity(0.9)
        default: PawColor.accent.opacity(0.9)
        }
    }
}

struct MiniRecapStep: View {
    var petName: String
    var isBirthdayToday: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var slide = 0

    private var slides: [String] {
        [
            "Meet \(petName)",
            "The little things add up",
            "A story worth keeping",
            "This is only the beginning"
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("A tiny film")
                .font(PawFont.body(.subheadline, weight: .semibold))
                .foregroundStyle(PawColor.secondary)
            Text("Here's the feeling of a recap. The real one is cut from \(petName)'s photos.")
                .font(PawFont.body())
                .foregroundStyle(PawColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [PawColor.primary, PawColor.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                VStack(spacing: 16) {
                    Image(systemName: "play.fill")
                        .font(.title2)
                        .foregroundStyle(PawColor.onPrimary.opacity(0.9))
                        .accessibilityHidden(true)
                    Text(slides[slide])
                        .font(PawFont.display(.title))
                        .foregroundStyle(PawColor.onPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .id(slide)
                    Text("9:16")
                        .font(PawFont.body(.caption, weight: .semibold))
                        .foregroundStyle(PawColor.onPrimary.opacity(0.8))
                }
                if isBirthdayToday {
                    ConfettiView()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 420)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Preview film. \(slides[slide])")

            HStack(spacing: 8) {
                ForEach(slides.indices, id: \.self) { index in
                    Circle()
                        .fill(index == slide ? PawColor.primary : PawColor.separator)
                        .frame(width: 8, height: 8)
                }
                Spacer()
                Button("Replay") { slide = 0 }
                    .font(PawFont.body(.subheadline, weight: .semibold))
                    .frame(minHeight: 44)
            }
        }
        .padding(.horizontal, 24)
        .task {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1.6))
                if Task.isCancelled { return }
                slide = (slide + 1) % slides.count
            }
        }
    }
}

struct NotificationStep: View {
    var prompt: String

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image(systemName: "bell.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(PawColor.primary)
                .frame(width: 84, height: 84)
                .background(PawColor.coralSoft, in: Circle())
                .accessibilityHidden(true)
            Text(prompt)
                .font(PawFont.display(.title))
                .foregroundStyle(PawColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text("A birthday, a monthly recap, a photo from a year ago. Never more than a few a week, and you can turn them off.")
                .font(PawFont.body())
                .foregroundStyle(PawColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Welcome") {
    WelcomeStep()
        .background(PawColor.background)
}

#Preview("Add pet") {
    @Previewable @State var draft = PetDraft(name: "Bella", species: .dog, breed: "Golden Retriever")
    ScrollView {
        AddPetStep(draft: $draft)
    }
    .background(PawColor.background)
}
