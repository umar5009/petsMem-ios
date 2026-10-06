import Foundation
import Observation

/// Remembers whether onboarding finished, and the draft if the app was closed mid-flow.
@MainActor
@Observable
final class OnboardingStore {
    private let defaults: UserDefaults
    private let completedKey = "pawmoir.onboarding.completed"
    private let stepKey = "pawmoir.onboarding.step"
    private let draftKey = "pawmoir.onboarding.draft"
    private let planKey = "pawmoir.onboarding.plan"

    var hasCompleted: Bool {
        didSet { defaults.set(hasCompleted, forKey: completedKey) }
    }

    init(defaults: UserDefaults) {
        self.defaults = defaults
        self.hasCompleted = defaults.bool(forKey: completedKey)
    }

    func savedStep() -> Int {
        defaults.integer(forKey: stepKey)
    }

    func save(step: Int) {
        defaults.set(step, forKey: stepKey)
    }

    func savedDraft() -> PetDraft.Persisted? {
        guard let data = defaults.data(forKey: draftKey) else { return nil }
        return try? JSONDecoder().decode(PetDraft.Persisted.self, from: data)
    }

    func save(draft: PetDraft) {
        guard let data = try? JSONEncoder().encode(draft.persisted) else { return }
        defaults.set(data, forKey: draftKey)
    }

    func savedPlan() -> PaywallPlan {
        guard let raw = defaults.string(forKey: planKey), let plan = PaywallPlan(rawValue: raw) else {
            return .yearly
        }
        return plan
    }

    func save(plan: PaywallPlan) {
        defaults.set(plan.rawValue, forKey: planKey)
    }

    func clearProgress() {
        defaults.removeObject(forKey: stepKey)
        defaults.removeObject(forKey: draftKey)
        defaults.removeObject(forKey: planKey)
    }

    func resetAll() {
        hasCompleted = false
        clearProgress()
    }
}
