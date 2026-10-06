import Foundation
import SwiftData
import Observation

enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome
    case addPet
    case photoAccess
    case magicMoment
    case miniRecap
    case paywall
    case notifications

    var id: Int { rawValue }

    var fraction: Double {
        Double(rawValue + 1) / Double(Self.allCases.count)
    }
}

/// Walks someone from the welcome line to a saved pet in under a minute.
@MainActor
@Observable
final class OnboardingViewModel {
    private(set) var step: OnboardingStep
    var draft: PetDraft
    private(set) var photoAuthorization: PhotoAuthorization
    private(set) var mediaCount = 0
    private(set) var didLoadMediaCount = false
    private(set) var revealedTiles = 0
    private(set) var isWorking = false
    var errorMessage: String?
    var selectedPlan: PaywallPlan
    private(set) var didRequestFinish = false
    private(set) var wantsSystemSettings = false

    /// Tests set this to zero so the grid does not sleep.
    var tileDelay: Duration = .milliseconds(70)

    private let photos: any PhotoLibraryService
    private let notifications: any NotificationScheduling
    private let entitlements: EntitlementManaging
    private let analytics: any AnalyticsService
    private let store: OnboardingStore
    private var magicTaskStarted = false
    private var didInsertPet = false

    init(
        photos: any PhotoLibraryService,
        notifications: any NotificationScheduling,
        entitlements: EntitlementManaging,
        analytics: any AnalyticsService,
        store: OnboardingStore,
        initialStep: OnboardingStep? = nil
    ) {
        self.photos = photos
        self.notifications = notifications
        self.entitlements = entitlements
        self.analytics = analytics
        self.store = store
        self.photoAuthorization = photos.authorizationStatus()
        if let saved = store.savedDraft() {
            self.draft = saved.restored(keepingAvatar: nil)
        } else {
            self.draft = PetDraft()
        }
        self.selectedPlan = store.savedPlan()
        if let initialStep {
            self.step = initialStep
        } else if store.hasCompleted {
            self.step = .welcome
        } else {
            self.step = OnboardingStep(rawValue: store.savedStep()) ?? .welcome
        }
    }

    var photoPrimaryTitle: String {
        switch photoAuthorization {
        case .authorized, .limited:
            "Continue"
        case .denied, .restricted:
            "Open Settings"
        case .notDetermined:
            "Allow photo access"
        }
    }

    var notificationPrompt: String {
        let name = draft.trimmedName.isEmpty ? "them" : draft.trimmedName
        if draft.hasDate {
            let day = draft.usesGotchaDay ? "gotcha day" : "birthday"
            return "Want a reminder on \(name)'s \(day)?"
        }
        return "Want a gentle nudge when a memory of \(name) is waiting?"
    }

    func persistDraft() {
        store.save(draft: draft)
    }

    func goBack() {
        guard step != .welcome, let previous = OnboardingStep(rawValue: step.rawValue - 1) else { return }
        leaveMagicIfNeeded()
        step = previous
        store.save(step: step.rawValue)
    }

    func continueForward() async {
        switch step {
        case .welcome:
            advance()
        case .addPet:
            guard draft.isValid else {
                errorMessage = "Add a name to continue."
                return
            }
            store.save(draft: draft)
            advance()
        case .photoAccess:
            await handlePhotoPrimary()
        case .magicMoment, .miniRecap:
            advance()
        case .paywall:
            startTrial()
        case .notifications:
            await requestNotifications()
        }
    }

    func skip() {
        switch step {
        case .photoAccess, .notifications:
            advance()
        case .paywall:
            analytics.track(AnalyticsEvent(.paywallSkipped, properties: ["plan": selectedPlan.rawValue]))
            advance()
        default:
            break
        }
    }

    func select(plan: PaywallPlan) {
        selectedPlan = plan
        store.save(plan: plan)
    }

    func startTrial() {
        entitlements.startTrial()
        let plan = selectedPlan
        Task { await entitlements.purchase(plan: plan) }
        analytics.track(AnalyticsEvent(.trialStarted, properties: ["plan": selectedPlan.rawValue]))
        Haptics.success()
        advance()
    }

    func clearSettingsRequest() {
        wantsSystemSettings = false
    }

    func beginMagicMoment() async {
        guard step == .magicMoment, !magicTaskStarted else { return }
        magicTaskStarted = true
        mediaCount = await photos.mediaCount()
        didLoadMediaCount = true
        let target = min(12, mediaCount)
        revealedTiles = 0
        guard target > 0 else { return }
        for index in 1...target {
            if Task.isCancelled { return }
            if tileDelay > .zero {
                try? await Task.sleep(for: tileDelay)
            }
            revealedTiles = index
        }
    }

    func finish(in context: ModelContext) {
        if !didInsertPet {
            let pet = draft.makePet()
            context.insert(pet)
            if let birthday = pet.birthday {
                context.insert(Milestone(type: .birthday, date: birthday, title: "Birthday", pet: pet))
            } else if let gotcha = pet.gotchaDay {
                context.insert(Milestone(type: .gotchaDay, date: gotcha, title: "Gotcha day", pet: pet))
            }
            didInsertPet = true
        }
        do {
            try context.save()
            store.hasCompleted = true
            store.clearProgress()
            analytics.track(AnalyticsEvent(.onboardingCompleted))
            analytics.track(AnalyticsEvent(.petCreated))
        } catch {
            didRequestFinish = false
            errorMessage = "We couldn't save \(draft.trimmedName). Please try again."
        }
    }

    private func handlePhotoPrimary() async {
        switch photoAuthorization {
        case .authorized, .limited:
            advance()
        case .denied, .restricted:
            wantsSystemSettings = true
        case .notDetermined:
            isWorking = true
            photoAuthorization = await photos.requestAccess()
            isWorking = false
            if photoAuthorization.canReadLibrary {
                advance()
            }
        }
    }

    private func requestNotifications() async {
        isWorking = true
        _ = await notifications.requestAuthorization()
        isWorking = false
        advance()
    }

    private func advance() {
        guard let next = OnboardingStep(rawValue: step.rawValue + 1) else {
            didRequestFinish = true
            return
        }
        leaveMagicIfNeeded()
        step = next
        store.save(step: step.rawValue)
        store.save(draft: draft)
        analytics.track(AnalyticsEvent(.onboardingStepViewed, properties: ["step": "\(next.rawValue)"]))
    }

    private func leaveMagicIfNeeded() {
        guard step == .magicMoment else { return }
        magicTaskStarted = false
        didLoadMediaCount = false
        revealedTiles = 0
    }
}
