import XCTest
import SwiftData
@testable import Pawmoir

@MainActor
final class OnboardingViewModelTests: XCTestCase {
    private var harness: OnboardingHarness!

    override func setUp() {
        super.setUp()
        harness = OnboardingHarness()
    }

    override func tearDown() {
        harness.tearDown()
        harness = nil
        super.tearDown()
    }

    func testNameIsRequiredBeforePhotoAccess() async {
        let model = harness.makeModel()
        await model.continueForward()
        XCTAssertEqual(model.step, .addPet)

        await model.continueForward()
        XCTAssertEqual(model.step, .addPet)
        XCTAssertEqual(model.errorMessage, "Add a name to continue.")

        model.draft.name = "  Bella  "
        await model.continueForward()
        XCTAssertEqual(model.step, .photoAccess)
        XCTAssertEqual(model.draft.trimmedName, "Bella")
    }

    func testSkippingPaywallDoesNotGrantPremium() {
        let model = harness.makeModel(step: .paywall)
        model.skip()
        XCTAssertEqual(model.step, .notifications)
        XCTAssertFalse(harness.entitlements.isPremium)
        XCTAssertTrue(harness.analytics.snapshot().contains(where: { $0.name == AnalyticsEvent.Name.paywallSkipped.rawValue }))
    }

    func testStartTrialGrantsLocalPremiumAndAdvances() {
        let model = harness.makeModel(step: .paywall)
        model.select(plan: .yearly)
        model.startTrial()
        XCTAssertTrue(harness.entitlements.isPremium)
        XCTAssertEqual(model.step, .notifications)
    }

    func testDeniedPhotoAccessAsksForSettingsAndDoesNotAdvance() async {
        harness.photos.status = .denied
        let model = harness.makeModel(step: .photoAccess)
        await model.continueForward()
        XCTAssertTrue(model.wantsSystemSettings)
        XCTAssertEqual(model.step, .photoAccess)
    }

    func testSkipPhotoAccessAdvancesWithoutAPrompt() {
        let model = harness.makeModel(step: .photoAccess)
        model.skip()
        XCTAssertEqual(model.step, .magicMoment)
        XCTAssertEqual(harness.photos.status, .notDetermined)
    }

    func testMagicMomentRevealsOneTilePerAvailableItemUpToTwelve() async {
        harness.photos.status = .authorized
        harness.photos.count = 4
        let model = harness.makeModel(step: .magicMoment)
        await model.beginMagicMoment()
        XCTAssertEqual(model.mediaCount, 4)
        XCTAssertEqual(model.revealedTiles, 4)
        XCTAssertTrue(model.didLoadMediaCount)
    }

    func testNotificationSkipFinishesTheFlow() {
        let model = harness.makeModel(step: .notifications)
        model.skip()
        XCTAssertTrue(model.didRequestFinish)
        XCTAssertFalse(harness.notifications.requested)
    }

    func testFinishSavesPetAndBirthdayMilestone() throws {
        let model = harness.makeModel(step: .notifications)
        model.draft.name = "Bella"
        model.draft.species = .dog
        model.draft.hasDate = true
        model.draft.usesGotchaDay = false
        let calendar = Calendar(identifier: .gregorian)
        model.draft.date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2024, month: 3, day: 2)))

        let container = try ModelContainerFactory.make(inMemory: true)
        model.finish(in: container.mainContext)

        XCTAssertTrue(harness.store.hasCompleted)
        let pets = try container.mainContext.fetch(FetchDescriptor<Pet>())
        XCTAssertEqual(pets.map(\.name), ["Bella"])
        let milestones = try container.mainContext.fetch(FetchDescriptor<Milestone>())
        XCTAssertEqual(milestones.map(\.title), ["Birthday"])
    }
}
