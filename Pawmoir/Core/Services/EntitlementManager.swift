import Foundation
import Observation
import StoreKit

/// What the rest of the app is allowed to ask.
/// A StoreKit-backed type will replace the purchase path later; call sites stay here.
@MainActor
protocol EntitlementManaging: AnyObject {
    var isPremium: Bool { get }
    func canAddPet(currentCount: Int) -> Bool
    func captionsRemaining(now: Date, calendar: Calendar) -> Int
    func consumeCaption(now: Date, calendar: Calendar) -> Bool
    func startTrial()
    func restore() -> Bool
    func clearLocalEntitlement()
    func purchase(plan: PaywallPlan) async
    func restorePurchases() async -> Bool
}

/// Local stand-in for StoreKit. A trial sets a flag on this device only.
/// It does not charge anyone and it will not survive a reinstall as a real subscription would.
@MainActor
@Observable
final class EntitlementManager: EntitlementManaging {
    static let freePetLimit = 1
    static let freeMonthlyCaptions = 5
    static let premiumPrintDiscountPercent = 15

    private(set) var isPremium: Bool

    private let defaults: UserDefaults
    private let premiumKey = "pawmoir.entitlement.premium"
    private let usedKey = "pawmoir.entitlement.captionsUsed"
    private let monthKey = "pawmoir.entitlement.captionMonth"
    private var used: Int

    init(defaults: UserDefaults) {
        self.defaults = defaults
        self.isPremium = defaults.bool(forKey: premiumKey)
        self.used = defaults.integer(forKey: usedKey)
    }

    func canAddPet(currentCount: Int) -> Bool {
        isPremium || currentCount < Self.freePetLimit
    }

    func captionsRemaining(now: Date, calendar: Calendar) -> Int {
        if isPremium { return Int.max }
        rollover(now: now, calendar: calendar)
        return max(0, Self.freeMonthlyCaptions - used)
    }

    func consumeCaption(now: Date, calendar: Calendar) -> Bool {
        if isPremium { return true }
        rollover(now: now, calendar: calendar)
        guard used < Self.freeMonthlyCaptions else { return false }
        used += 1
        defaults.set(used, forKey: usedKey)
        return true
    }

    func startTrial() {
        isPremium = true
        defaults.set(true, forKey: premiumKey)
    }

    /// StoreKit when the products are loaded. A local trial otherwise, so the simulator and tests still move.
    func purchase(plan: PaywallPlan) async {
        do {
            let products = try await Product.products(for: [plan.productID])
            guard let product = products.first else {
                startTrial()
                return
            }
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    startTrial()
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            startTrial()
        }
    }

    func restorePurchases() async -> Bool {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            let ids = [PaywallPlan.monthly.productID, PaywallPlan.yearly.productID]
            if ids.contains(transaction.productID) {
                startTrial()
                return true
            }
        }
        return restore()
    }

    @discardableResult
    func restore() -> Bool {
        isPremium = defaults.bool(forKey: premiumKey)
        return isPremium
    }

    func clearLocalEntitlement() {
        isPremium = false
        used = 0
        defaults.removeObject(forKey: premiumKey)
        defaults.removeObject(forKey: usedKey)
        defaults.removeObject(forKey: monthKey)
    }

    private func rollover(now: Date, calendar: Calendar) {
        let parts = calendar.dateComponents([.year, .month], from: now)
        let token = "\(parts.year ?? 0)-\(parts.month ?? 0)"
        let stored = defaults.string(forKey: monthKey)
        guard stored != token else { return }
        used = 0
        defaults.set(0, forKey: usedKey)
        defaults.set(token, forKey: monthKey)
    }
}

extension EntitlementManaging {
    func purchase(plan: PaywallPlan) async {
        startTrial()
    }

    func restorePurchases() async -> Bool {
        restore()
    }

    func captionsRemaining() -> Int {
        captionsRemaining(now: .now, calendar: .current)
    }

    func consumeCaption() -> Bool {
        consumeCaption(now: .now, calendar: .current)
    }
}
