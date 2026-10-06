import XCTest
@testable import Pawmoir

@MainActor
final class EntitlementManagerTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName = ""
    private var manager: EntitlementManager!

    override func setUp() {
        super.setUp()
        let fresh = TestDefaults.fresh()
        defaults = fresh.0
        suiteName = fresh.1
        manager = EntitlementManager(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testFreePlanAllowsOnePet() {
        XCTAssertTrue(manager.canAddPet(currentCount: 0))
        XCTAssertFalse(manager.canAddPet(currentCount: 1))
        manager.startTrial()
        XCTAssertTrue(manager.canAddPet(currentCount: 5))
    }

    func testFreeCaptionsStopAtFiveAndResetNextMonth() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let january = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 1, day: 20)))
        let february = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 2, day: 1)))

        for _ in 0..<5 {
            XCTAssertTrue(manager.consumeCaption(now: january, calendar: calendar))
        }
        XCTAssertFalse(manager.consumeCaption(now: january, calendar: calendar))
        XCTAssertEqual(manager.captionsRemaining(now: january, calendar: calendar), 0)
        XCTAssertEqual(manager.captionsRemaining(now: february, calendar: calendar), 5)
        XCTAssertTrue(manager.consumeCaption(now: february, calendar: calendar))
    }

    func testPremiumCaptionsAreNotCounted() throws {
        manager.startTrial()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 1)))
        for _ in 0..<8 {
            XCTAssertTrue(manager.consumeCaption(now: now, calendar: calendar))
        }
        XCTAssertEqual(manager.captionsRemaining(now: now, calendar: calendar), Int.max)
    }

    func testRestoreReadsTheLocalFlag() {
        XCTAssertFalse(manager.restore())
        manager.startTrial()
        let reloaded = EntitlementManager(defaults: defaults)
        XCTAssertTrue(reloaded.restore())
        reloaded.clearLocalEntitlement()
        XCTAssertFalse(reloaded.isPremium)
    }
}
