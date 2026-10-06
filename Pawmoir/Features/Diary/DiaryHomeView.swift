import SwiftUI
import SwiftData

private enum DiaryPane: String, CaseIterable, Identifiable {
    case timeline
    case albums
    case calendar

    var id: String { rawValue }
    var title: String {
        switch self {
        case .timeline: "Timeline"
        case .albums: "Albums"
        case .calendar: "Calendar"
        }
    }
}

struct DiaryHomeView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Pet.createdAt) private var pets: [Pet]
    @Query(sort: \MemoryEntry.date, order: .reverse) private var memories: [MemoryEntry]
    var onQuickAdd: () -> Void

    @State private var selectedPetID: UUID?
    @State private var pane: DiaryPane = .timeline
    @State private var isScanning = false
    @State private var progress: Double = 0
    @State private var status = ""
    @Namespace private var photoZoom

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !dependencies.network.isOnline {
                    OfflineBanner(message: "You're offline. The diary is still on this iPhone.")
                }
                if pets.count > 1 { petFilters }
                if let pet = activePet { petHeader(pet) }
                if isScanning { scanBanner }
                panePicker
                switch pane {
                case .timeline:
                    timeline
                case .albums:
                    albums
                case .calendar:
                    CalendarHeatmap(memories: visibleMemories)
                }
            }
            .padding(20)
        }
        .navigationTitle("Diary")
        .background(PawColor.background)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if dependencies.photos.authorizationStatus() == .limited {
                    Button("Choose photos") {
                        PhotoKitLibraryService.presentLimitedPicker()
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await scan() }
                } label: {
                    Image(systemName: "photo.on.rectangle.angled")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Look through photos")
                .disabled(isScanning || pets.isEmpty)
            }
        }
        .task {
            WidgetSnapshotWriter.refresh(pets: pets, memories: memories)
            if memories.filter({ $0.assetLocalIdentifier != nil }).isEmpty {
                await scan()
            }
        }
    }

    private var activePet: Pet? {
        if let selectedPetID, let match = pets.first(where: { $0.id == selectedPetID }) {
            return match
        }
        return pets.first
    }

    private var visibleMemories: [MemoryEntry] {
        guard let id = activePet?.id, pets.count > 1 else { return memories }
        return memories.filter { $0.pets.contains(where: { $0.id == id }) }
    }

    private var petFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(pets) { pet in
                    SelectableChip(title: pet.name, isSelected: activePet?.id == pet.id) {
                        selectedPetID = pet.id
                    }
                }
            }
        }
    }

    private func petHeader(_ pet: Pet) -> some View {
        HStack(spacing: 14) {
            PetAvatar(imageData: pet.avatarJPEG, name: pet.name, species: pet.species, size: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text(pet.name)
                    .font(PawFont.title())
                    .foregroundStyle(PawColor.textPrimary)
                if pet.isMemorial {
                    Text("In loving memory")
                        .font(PawFont.body(.subheadline))
                        .foregroundStyle(PawColor.textSecondary)
                } else if let age = PetAgeCalculator.age(species: pet.species, birthday: pet.birthday, gotchaDay: pet.gotchaDay) {
                    Text("\(age.humanSummary) · \(age.petYears) pet years")
                        .font(PawFont.body(.subheadline))
                        .foregroundStyle(PawColor.textSecondary)
                }
            }
            Spacer()
        }
    }

    private var scanBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(status.isEmpty ? "Looking through photos on this iPhone" : status)
                .font(PawFont.body(.subheadline))
            ProgressView(value: progress)
                .tint(PawColor.primary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PawColor.coralSoft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var panePicker: some View {
        HStack(spacing: 8) {
            ForEach(DiaryPane.allCases) { item in
                SelectableChip(title: item.title, isSelected: pane == item) {
                    pane = item
                }
            }
        }
    }

    private var timeline: some View {
        VStack(alignment: .leading, spacing: 16) {
            onThisDaySection
            let pending = visibleMemories.filter(\.needsConfirmation)
            if !pending.isEmpty {
                Text("Check a few matches")
                    .font(PawFont.title(.headline))
                ForEach(pending.prefix(3)) { memory in
                    NavigationLink {
                        MemoryDetailView(memory: memory)
                    } label: {
                        memoryRow(memory)
                    }
                    .buttonStyle(.plain)
                }
            }
            if visibleMemories.isEmpty {
                EmptyStateView(
                    systemImage: "book.closed",
                    title: "The diary is open",
                    message: "Pawmoir can look for pet photos on this iPhone, or you can write the first note.",
                    actionTitle: "Add a memory",
                    action: onQuickAdd
                )
            } else {
                ForEach(grouped.keys.sorted(by: >), id: \.self) { month in
                    Text(monthTitle(month))
                        .font(PawFont.title(.headline))
                    ForEach(grouped[month] ?? []) { memory in
                        NavigationLink {
                            MemoryDetailView(memory: memory)
                        } label: {
                            memoryRow(memory)
                        }
                        .buttonStyle(.plain)
                        .matchedGeometryEffect(id: memory.id, in: photoZoom)
                    }
                }
            }
        }
    }

    private func memoryRow(_ memory: MemoryEntry) -> some View {
        MemoryCard(
            date: memory.date,
            note: memory.note.isEmpty ? (memory.needsConfirmation ? "Is this the right pet?" : "A moment from the camera roll") : memory.note,
            mood: memory.mood,
            petName: memory.pets.first?.name ?? "Pet",
            location: memory.locationName,
            assetLocalIdentifier: memory.assetLocalIdentifier
        )
    }

    private var onThisDaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("On this day")
                .font(PawFont.title(.headline))
            if onThisDay.isEmpty {
                Text("When a date lines up with another year, it will show here.")
                    .font(PawFont.body(.subheadline))
                    .foregroundStyle(PawColor.textSecondary)
            } else {
                ForEach(onThisDay) { memory in
                    memoryRow(memory)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PawColor.sageSoft, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var albums: some View {
        VStack(spacing: 12) {
            ForEach(SmartAlbum.allCases) { album in
                let count = visibleMemories.filter { $0.albumTags.contains(album.rawValue) }.count
                HStack {
                    Image(systemName: album.symbolName)
                        .foregroundStyle(PawColor.primary)
                        .frame(width: 36)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading) {
                        Text(album.title)
                            .font(PawFont.title(.headline))
                        Text("\(count) moments")
                            .font(PawFont.body(.footnote))
                            .foregroundStyle(PawColor.textSecondary)
                    }
                    Spacer()
                }
                .padding(14)
                .frame(minHeight: 44)
                .background(PawColor.surfaceElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var grouped: [Date: [MemoryEntry]] {
        let calendar = Calendar.current
        return Dictionary(grouping: visibleMemories.filter { !$0.needsConfirmation || $0.note.isEmpty == false || $0.assetLocalIdentifier != nil }) { memory in
            let parts = calendar.dateComponents([.year, .month], from: memory.date)
            return calendar.date(from: parts) ?? memory.date
        }
    }

    private var onThisDay: [MemoryEntry] {
        let calendar = Calendar.current
        let today = calendar.dateComponents([.month, .day, .year], from: .now)
        return visibleMemories.filter { memory in
            let parts = calendar.dateComponents([.month, .day, .year], from: memory.date)
            return parts.month == today.month && parts.day == today.day && parts.year != today.year
        }
    }

    private func monthTitle(_ date: Date) -> String {
        date.formatted(.dateTime.month(.wide).year())
    }

    private func scan() async {
        guard !pets.isEmpty, !isScanning else { return }
        let status = dependencies.photos.authorizationStatus()
        guard status.canReadLibrary else {
            self.status = "Photo access is off. You can still write notes."
            return
        }
        isScanning = true
        progress = 0
        self.status = "Matching pets on this iPhone. Nothing is uploaded."
        let profiles = pets.map {
            PetScanProfile(id: $0.id, species: $0.species, anchor: $0.ageAnchor, featurePrint: $0.featurePrintData)
        }
        let known = Set(memories.compactMap(\.assetLocalIdentifier))
        let hits = await PhotoLibraryScanner().scan(pets: profiles, existingIDs: known, limit: 180) { fraction in
            Task { @MainActor in
                progress = fraction
            }
        }
        DiaryImporter.importHits(hits, pets: pets, into: modelContext)
        WidgetSnapshotWriter.refresh(pets: pets, memories: memories)
        self.status = hits.isEmpty ? "No new pet photos in the latest batch." : "Added \(hits.filter(\.isBestOfBurst).count) moments."
        isScanning = false
        LibraryScanCoordinator.schedule()
    }
}

struct CalendarHeatmap: View {
    var memories: [MemoryEntry]
    @State private var month = Date.now

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button {
                    shift(-1)
                } label: {
                    Image(systemName: "chevron.left").frame(width: 44, height: 44)
                }
                .accessibilityLabel("Previous month")
                Spacer()
                Text(month.formatted(.dateTime.month(.wide).year()))
                    .font(PawFont.title(.headline))
                Spacer()
                Button {
                    shift(1)
                } label: {
                    Image(systemName: "chevron.right").frame(width: 44, height: 44)
                }
                .accessibilityLabel("Next month")
            }
            let days = daysInMonth()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(days, id: \.self) { day in
                    let count = count(on: day)
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(color(for: count))
                        .frame(height: 28)
                        .accessibilityLabel("\(day.formatted(.dateTime.day().month())), \(count) memories")
                }
            }
        }
    }

    private func shift(_ value: Int) {
        month = Calendar.current.date(byAdding: .month, value: value, to: month) ?? month
    }

    private func daysInMonth() -> [Date] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            return []
        }
        return range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: start) }
    }

    private func count(on day: Date) -> Int {
        let calendar = Calendar.current
        return memories.filter { calendar.isDate($0.date, inSameDayAs: day) }.count
    }

    private func color(for count: Int) -> Color {
        switch count {
        case 0: PawColor.separator.opacity(0.5)
        case 1: PawColor.secondary.opacity(0.45)
        case 2...3: PawColor.secondary
        default: PawColor.primary
        }
    }
}

enum WidgetSnapshotWriter {
    @MainActor
    static func refresh(pets: [Pet], memories: [MemoryEntry]) {
        guard let pet = pets.first else { return }
        let calendar = Calendar.current
        let today = calendar.dateComponents([.month, .day], from: .now)
        let memory = memories.first { entry in
            let parts = calendar.dateComponents([.month, .day], from: entry.date)
            return parts.month == today.month && parts.day == today.day
        } ?? memories.first
        let age = PetAgeCalculator.age(species: pet.species, birthday: pet.birthday, gotchaDay: pet.gotchaDay)
        let snapshot = WidgetSnapshot(
            petName: pet.name,
            ageText: age.map { "\($0.humanSummary) · \($0.petYears) pet years" } ?? pet.species.title,
            note: memory?.note.isEmpty == false ? (memory?.note ?? "") : "On this day",
            photoJPEG: nil
        )
        WidgetSnapshotStore.save(snapshot)
    }
}
