import SwiftUI
import SwiftData
import UIKit

struct OnboardingFlow: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model: OnboardingViewModel?

    var body: some View {
        Group {
            if let model {
                flow(model)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(PawColor.background.ignoresSafeArea())
        .onAppear {
            if model == nil {
                model = OnboardingViewModel(
                    photos: dependencies.photos,
                    notifications: dependencies.notifications,
                    entitlements: dependencies.entitlements,
                    analytics: dependencies.analytics,
                    store: dependencies.onboardingStore
                )
            }
        }
    }

    private func flow(_ model: OnboardingViewModel) -> some View {
        VStack(spacing: 0) {
            header(model)
            if model.step == .paywall {
                BoundPaywall(model: model)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    step(model)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .safeAreaInset(edge: .bottom) {
            controls(model)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .background(PawColor.background)
        }
        .animation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.86), value: model.step)
        .alert("Something went wrong", isPresented: errorBinding(model)) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
        .onChange(of: model.didRequestFinish) { _, finished in
            if finished {
                model.finish(in: modelContext)
            }
        }
        .onChange(of: model.wantsSystemSettings) { _, wants in
            guard wants, let url = URL(string: UIApplication.openSettingsURLString) else { return }
            model.clearSettingsRequest()
            UIApplication.shared.open(url)
        }
        .task(id: model.step) {
            await model.beginMagicMoment()
        }
    }

    private func header(_ model: OnboardingViewModel) -> some View {
        HStack(spacing: 12) {
            if model.step != .welcome {
                Button {
                    model.goBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Back")
                .tint(PawColor.textPrimary)
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
            ProgressView(value: model.step.fraction)
                .tint(PawColor.primary)
                .accessibilityLabel("Step \(model.step.rawValue + 1) of \(OnboardingStep.allCases.count)")
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    @ViewBuilder
    private func step(_ model: OnboardingViewModel) -> some View {
        switch model.step {
        case .welcome:
            WelcomeStep()
        case .addPet:
            BoundAddPet(model: model)
        case .photoAccess:
            PhotoAccessStep(
                petName: model.draft.trimmedName.isEmpty ? "your pet" : model.draft.trimmedName,
                authorization: model.photoAuthorization,
                onManageLimited: { PhotoKitLibraryService.presentLimitedPicker() }
            )
        case .magicMoment:
            MagicMomentStep(
                petName: model.draft.trimmedName.isEmpty ? "them" : model.draft.trimmedName,
                mediaCount: model.mediaCount,
                revealedTiles: model.revealedTiles,
                isReady: model.didLoadMediaCount
            )
        case .miniRecap:
            MiniRecapStep(
                petName: model.draft.trimmedName.isEmpty ? "your pet" : model.draft.trimmedName,
                isBirthdayToday: isAnniversaryToday(model.draft)
            )
        case .paywall:
            EmptyView()
        case .notifications:
            NotificationStep(prompt: model.notificationPrompt)
        }
    }

    @ViewBuilder
    private func controls(_ model: OnboardingViewModel) -> some View {
        switch model.step {
        case .welcome:
            PrimaryButton(title: "Begin", identifier: "onboarding.welcome.begin") {
                Task { await model.continueForward() }
            }
        case .addPet:
            PrimaryButton(
                title: "Continue",
                isEnabled: model.draft.isValid,
                identifier: "onboarding.pet.continue"
            ) {
                Task { await model.continueForward() }
            }
        case .photoAccess:
            VStack(spacing: 10) {
                PrimaryButton(
                    title: LocalizedStringKey(model.photoPrimaryTitle),
                    isLoading: model.isWorking,
                    identifier: "onboarding.photos.allow"
                ) {
                    Task { await model.continueForward() }
                }
                PrimaryButton(title: "I'll add photos myself", style: .plain, identifier: "onboarding.photos.skip") {
                    model.skip()
                }
            }
        case .magicMoment:
            PrimaryButton(title: "Continue", identifier: "onboarding.magic.continue") {
                Task { await model.continueForward() }
            }
        case .miniRecap:
            PrimaryButton(title: "Continue", identifier: "onboarding.recap.continue") {
                Task { await model.continueForward() }
            }
        case .paywall:
            EmptyView()
        case .notifications:
            VStack(spacing: 10) {
                PrimaryButton(
                    title: "Yes, remind me",
                    isLoading: model.isWorking,
                    identifier: "onboarding.notifications.allow"
                ) {
                    Task { await model.continueForward() }
                }
                PrimaryButton(title: "Not now", style: .plain, identifier: "onboarding.notifications.skip") {
                    model.skip()
                }
            }
        }
    }

    private func errorBinding(_ model: OnboardingViewModel) -> Binding<Bool> {
        Binding(
            get: { model.errorMessage != nil },
            set: { isPresented in
                if !isPresented { model.errorMessage = nil }
            }
        )
    }

    private struct BoundAddPet: View {
        @Bindable var model: OnboardingViewModel

        var body: some View {
            AddPetStep(draft: $model.draft)
                .onChange(of: model.draft.persisted) { _, _ in
                    model.persistDraft()
                }
        }
    }

    private struct BoundPaywall: View {
        var model: OnboardingViewModel

        var body: some View {
            PaywallView(
                petName: model.draft.trimmedName,
                allowsSkip: true,
                selectedPlan: Binding(
                    get: { model.selectedPlan },
                    set: { model.select(plan: $0) }
                ),
                isWorking: model.isWorking,
                onStartTrial: { model.startTrial() },
                onSkip: { model.skip() }
            )
        }
    }

    private func isAnniversaryToday(_ draft: PetDraft) -> Bool {
        guard draft.hasDate else { return false }
        return Calendar.current.isDate(draft.date, inSameDayAs: .now)
    }
}

#Preview("Onboarding") {
    let dependencies = AppDependencies.preview(onboarded: false, mediaCount: 412)
    OnboardingFlow()
        .environment(dependencies)
        .modelContainer(dependencies.modelContainer)
}
