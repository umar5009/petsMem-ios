import SwiftUI
import SwiftData

struct StudioTemplate: Identifiable, Equatable {
    var id: String
    var title: String
    var symbol: String
    var isPremium: Bool
}

enum StudioCatalog {
    static var templates: [StudioTemplate] { StudioTemplateLibrary.all }
}

struct StudioHomeView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Query(sort: \Pet.createdAt) private var pets: [Pet]
    @State private var tone: CaptionTone = .funny
    @State private var captions: [String] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showPaywall = false
    @State private var selectedPlan: PaywallPlan = .yearly
    @State private var info: String?
    @State private var reported = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if !dependencies.network.isOnline {
                    OfflineBanner(message: "You're offline. This preview stays on your phone. Live captions need a connection later.")
                }
                Text("Turn a moment into something you can share.")
                    .font(PawFont.body())
                    .foregroundStyle(PawColor.textSecondary)

                captionCard
                toolRow
                templateRow
            }
            .padding(20)
        }
        .navigationTitle("Create")
        .background(PawColor.background)
        .sheet(isPresented: $showPaywall) {
            NavigationStack {
                PaywallView(
                    petName: pets.first?.name,
                    allowsSkip: true,
                    selectedPlan: $selectedPlan,
                    onStartTrial: {
                        dependencies.entitlements.startTrial()
                        showPaywall = false
                    },
                    onSkip: { showPaywall = false }
                )
                .navigationTitle("Premium")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .alert("Studio", isPresented: Binding(
            get: { info != nil },
            set: { if !$0 { info = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(info ?? "")
        }
        .alert("Couldn't write a caption", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var captionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What they're thinking")
                .font(PawFont.title())
            Text(allowanceLine)
                .font(PawFont.body(.footnote))
                .foregroundStyle(PawColor.textSecondary)
            FlowLayout(spacing: 8) {
                ForEach(CaptionTone.allCases) { item in
                    SelectableChip(title: item.title, isSelected: tone == item) {
                        tone = item
                    }
                }
            }
            PrimaryButton(title: "Preview a caption", isLoading: isLoading) {
                Task { await previewCaption() }
            }
            ForEach(captions, id: \.self) { line in
                Text(line)
                    .font(PawFont.body())
                    .foregroundStyle(PawColor.textPrimary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(PawColor.coralSoft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            if !captions.isEmpty {
                Button(reported ? "Report noted" : "Report caption") {
                    dependencies.analytics.track(AnalyticsEvent(.captionReported))
                    reported = true
                }
                .font(PawFont.body(.footnote, weight: .semibold))
                .frame(minHeight: 44)
                .disabled(reported)
            }
        }
        .padding(16)
        .background(PawColor.surfaceElevated, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var allowanceLine: String {
        if dependencies.entitlements.isPremium {
            return "Premium · unlimited previews"
        }
        let remaining = dependencies.entitlements.captionsRemaining()
        return "\(remaining) of \(EntitlementManager.freeMonthlyCaptions) free captions left this month"
    }

    private var toolRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Films")
                .font(PawFont.title(.headline))
            NavigationLink {
                RecapStudioView(kind: .birthday)
            } label: {
                toolLabel("Birthday film", "A morning-of video with their name, age, and best photos.")
            }
            .buttonStyle(.plain)
            NavigationLink {
                RecapStudioView(kind: .wrapped)
            } label: {
                toolLabel("Pet Wrapped", "A year in numbers and a highlight reel.")
            }
            .buttonStyle(.plain)
            NavigationLink {
                RecapStudioView(kind: .monthly)
            } label: {
                toolLabel("Monthly recap", "A short film. Free exports keep a small watermark.")
            }
            .buttonStyle(.plain)
        }
    }

    private func toolLabel(_ title: String, _ message: String) -> some View {
        HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(PawFont.title(.headline))
                        .foregroundStyle(PawColor.textPrimary)
                    Text(message)
                        .font(PawFont.body(.footnote))
                        .foregroundStyle(PawColor.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(PawColor.textTertiary)
                    .accessibilityHidden(true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .background(PawColor.surfaceElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var templateRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Templates")
                .font(PawFont.title(.headline))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(StudioCatalog.templates) { template in
                        NavigationLink {
                            RecapStudioView(kind: .template(template.id))
                        } label: {
                            TemplateCard(
                                title: template.title,
                                systemImage: template.symbol,
                                isLocked: template.isPremium && !dependencies.entitlements.isPremium
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(template.isPremium && !dependencies.entitlements.isPremium && template.id != "memorial")
                        .simultaneousGesture(TapGesture().onEnded {
                            if template.isPremium && !dependencies.entitlements.isPremium && template.id != "memorial" {
                                showPaywall = true
                            }
                        })
                    }
                }
            }
        }
    }

    private func previewCaption() async {
        guard let pet = pets.first else {
            info = "Add a pet first, then we can write in their voice."
            return
        }
        guard dependencies.entitlements.captionsRemaining() > 0 else {
            if pet.isMemorial {
                info = "Captions can wait. The tribute page is still here."
            }
            showPaywall = !pet.isMemorial
            return
        }
        let safeTone: CaptionTone = pet.isMemorial && (tone == .funny || tone == .sassy) ? .wholesome : tone
        isLoading = true
        defer { isLoading = false }
        do {
            let lines = try await dependencies.ai.captions(for: CaptionRequest(
                petName: pet.name,
                species: pet.species,
                personalityTags: pet.personalityTags,
                tone: safeTone
            ))
            guard dependencies.entitlements.consumeCaption() else {
                showPaywall = true
                return
            }
            captions = lines
            reported = false
            dependencies.analytics.track(AnalyticsEvent(.captionPreviewed, properties: ["tone": tone.rawValue]))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview("Create") {
    let dependencies = AppDependencies.preview()
    NavigationStack {
        StudioHomeView()
    }
    .environment(dependencies)
    .modelContainer(dependencies.modelContainer)
}
