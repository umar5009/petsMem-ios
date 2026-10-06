import SwiftUI
import SwiftData
import UIKit

enum RecapKind: Hashable {
    case birthday
    case wrapped
    case monthly
    case template(String)

    var title: String {
        switch self {
        case .birthday: "Birthday film"
        case .wrapped: "Pet Wrapped"
        case .monthly: "Monthly recap"
        case .template(let id):
            StudioTemplateLibrary.all.first { $0.id == id }?.title ?? "Template"
        }
    }
}

struct RecapStudioView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Pet.createdAt) private var pets: [Pet]
    @Query(sort: \MemoryEntry.date, order: .reverse) private var memories: [MemoryEntry]
    var kind: RecapKind

    @State private var aspect: ExportAspect = .story
    @State private var trackID = MusicTrack.library[0].id
    @State private var captionText = ""
    @State private var progress: Double = 0
    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var stillImage: UIImage?
    @State private var errorMessage: String?
    @State private var showPaywall = false
    @State private var selectedPlan: PaywallPlan = .yearly
    @State private var exportTask: Task<Void, Never>?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let pet = activePet, pet.isMemorial {
                    Text("A quiet film. Playful captions stay off for \(pet.name).")
                        .font(PawFont.body())
                        .foregroundStyle(PawColor.textSecondary)
                }
                if !dependencies.network.isOnline {
                    OfflineBanner(message: "Export stays on this iPhone. Sharing can wait for a connection.")
                }
                stats
                Picker("Shape", selection: $aspect) {
                    ForEach(ExportAspect.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                TextField("Words on the film", text: $captionText, axis: .vertical)
                    .lineLimit(2...4)
                    .padding(12)
                    .background(PawColor.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                musicRow
                if isExporting {
                    ProgressView(value: progress)
                        .tint(PawColor.primary)
                    Button("Cancel export") { exportTask?.cancel() }
                        .frame(minHeight: 44)
                }
                PrimaryButton(title: "Export", isLoading: isExporting) {
                    exportTask = Task { await export() }
                }
                if let stillImage {
                    Image(uiImage: stillImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 360)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .accessibilityLabel("Export preview")
                }
                if let exportURL {
                    ShareLink(item: exportURL) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    if let stillImage {
                        Button("Instagram Stories") {
                            StoryShare.share(image: stillImage)
                        }
                        .frame(minHeight: 44)
                    }
                }
                if ExportPolicy.includesWatermark(isPremium: dependencies.entitlements.isPremium) {
                    Text("Free exports include “\(ExportPolicy.watermarkText)”. Premium removes it.")
                        .font(PawFont.body(.footnote))
                        .foregroundStyle(PawColor.textSecondary)
                }
            }
            .padding(20)
        }
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(PawColor.background)
        .onAppear {
            if captionText.isEmpty, let pet = activePet {
                captionText = defaultCaption(for: pet)
            }
        }
        .sheet(isPresented: $showPaywall) {
            NavigationStack {
                PaywallView(
                    petName: activePet?.name,
                    allowsSkip: true,
                    selectedPlan: $selectedPlan,
                    onStartTrial: {
                        Task { await dependencies.entitlements.purchase(plan: selectedPlan) }
                        showPaywall = false
                    },
                    onSkip: { showPaywall = false }
                )
            }
        }
        .alert("Export", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var activePet: Pet? { pets.first }

    private var chosenMemories: [MemoryEntry] {
        let withPhotos = memories.filter { $0.assetLocalIdentifier != nil && $0.isBestOfBurst }
        let calendar = Calendar.current
        switch kind {
        case .monthly:
            return withPhotos.filter { calendar.isDate($0.date, equalTo: .now, toGranularity: .month) }
        case .wrapped, .birthday:
            return withPhotos.filter { calendar.isDate($0.date, equalTo: .now, toGranularity: .year) }
        case .template:
            return Array(withPhotos.prefix(4))
        }
    }

    private var stats: some View {
        let count = chosenMemories.count
        return VStack(alignment: .leading, spacing: 6) {
            Text("\(count) photos in this cut")
                .font(PawFont.title(.headline))
            if case .wrapped = kind, let pet = activePet {
                Text("\(pet.name) · \(memories.count) moments kept")
                    .font(PawFont.body(.subheadline))
                    .foregroundStyle(PawColor.textSecondary)
            }
        }
    }

    private var musicRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Music")
                .font(PawFont.title(.headline))
            Text("Original tones made in Pawmoir. Not recordings from a label.")
                .font(PawFont.body(.footnote))
                .foregroundStyle(PawColor.textSecondary)
            FlowLayout(spacing: 8) {
                ForEach(MusicTrack.library) { track in
                    let locked = track.isPremium && !dependencies.entitlements.isPremium
                    SelectableChip(title: locked ? "\(track.title) lock" : track.title, isSelected: trackID == track.id) {
                        if locked {
                            showPaywall = true
                        } else {
                            trackID = track.id
                        }
                    }
                }
            }
        }
    }

    private func defaultCaption(for pet: Pet) -> String {
        if pet.isMemorial { return "In loving memory of \(pet.name)" }
        switch kind {
        case .birthday:
            let age = PetAgeCalculator.age(species: pet.species, birthday: pet.birthday, gotchaDay: pet.gotchaDay)
            return age.map { "\(pet.name) · \($0.humanSummary)" } ?? pet.name
        case .wrapped:
            return "\(pet.name)'s year"
        case .monthly:
            return "\(pet.name) this month"
        case .template:
            return pet.name
        }
    }

    private func export() async {
        if case .template(let id) = kind,
           let template = StudioTemplateLibrary.all.first(where: { $0.id == id }),
           template.isPremium,
           !dependencies.entitlements.isPremium,
           template.id != "memorial" {
            showPaywall = true
            return
        }
        isExporting = true
        progress = 0
        defer { isExporting = false }
        let images = await loadImages()
        let watermark = ExportPolicy.includesWatermark(isPremium: dependencies.entitlements.isPremium)
        let track = MusicTrack.library.first { $0.id == trackID } ?? MusicTrack.library[0]
        do {
            let url = try await SlideshowExporter.export(
                images: images,
                title: activePet?.name ?? "Pawmoir",
                subtitle: captionText,
                aspect: aspect,
                track: track,
                watermark: watermark
            ) { value in
                Task { @MainActor in progress = value }
            }
            if Task.isCancelled { return }
            exportURL = url
            stillImage = SlideshowExporter.still(image: images.first, text: captionText, aspect: aspect, watermark: watermark)
            let creation = Creation(
                type: kindIsVideo ? .video : .collage,
                templateID: templateID,
                assetIdentifiers: chosenMemories.compactMap(\.assetLocalIdentifier),
                exportPath: url.path,
                petID: activePet?.id,
                pet: activePet
            )
            modelContext.insert(creation)
            try? modelContext.save()
            Haptics.success()
        } catch is CancellationError {
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var kindIsVideo: Bool {
        if case .template = kind { return false }
        return true
    }

    private var templateID: String? {
        if case .template(let id) = kind { return id }
        return nil
    }

    private func loadImages() async -> [UIImage] {
        var images: [UIImage] = []
        for memory in chosenMemories.prefix(6) {
            guard let id = memory.assetLocalIdentifier else { continue }
            if let image = await ThumbnailLoader.shared.image(for: id, side: 800) {
                images.append(image)
            }
        }
        return images
    }
}

enum StoryShare {
    static func share(image: UIImage) {
        guard let url = URL(string: "instagram-stories://share?source_application=com.pawmoir.app"),
              let data = image.pngData() else { return }
        guard UIApplication.shared.canOpenURL(url) else { return }
        let item: [String: Any] = ["com.instagram.sharedSticker.backgroundImage": data]
        UIPasteboard.general.setItems([item], options: [
            .expirationDate: Date().addingTimeInterval(60 * 5)
        ])
        UIApplication.shared.open(url)
    }
}
