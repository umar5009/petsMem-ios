import XCTest
@testable import Pawmoir

final class PhaseEnginesTests: XCTestCase {
    func testPetMatcherAsksForConfirmationWhenPetsAreClose() {
        let first = UUID()
        let second = UUID()
        let choice = PetMatcher.choose(distances: [
            PetMatcher.Choice(petID: first, distance: 0.40),
            PetMatcher.Choice(petID: second, distance: 0.48)
        ])
        XCTAssertEqual(choice?.petID, first)
        XCTAssertEqual(choice?.needsConfirmation, true)
    }

    func testPetMatcherRejectsADistantPrint() {
        let choice = PetMatcher.choose(distances: [
            PetMatcher.Choice(petID: UUID(), distance: 0.9)
        ])
        XCTAssertNil(choice)
    }

    func testBurstPickerKeepsTheSharpestFrame() {
        let winner = BurstPicker.winnerID(in: [
            BurstPicker.Frame(assetID: "soft", sharpness: 2),
            BurstPicker.Frame(assetID: "crisp", sharpness: 9)
        ])
        XCTAssertEqual(winner, "crisp")
    }

    func testFreeExportsCarryTheWatermark() {
        XCTAssertTrue(ExportPolicy.includesWatermark(isPremium: false))
        XCTAssertFalse(ExportPolicy.includesWatermark(isPremium: true))
        XCTAssertEqual(ExportPolicy.watermarkText, "Made with Pawmoir")
        XCTAssertEqual(ExportAspect.story.pixelSize, CGSize(width: 1080, height: 1920))
    }

    func testBookLayoutUsesOnePageForCanvas() {
        let book = BookAutolayout.make(
            title: "Bella",
            product: .canvas,
            items: [("asset", "A note")]
        )
        XCTAssertEqual(book.pages.count, 1)
        XCTAssertEqual(book.pages.first?.assetIdentifiers, ["asset"])
    }

    func testPrintQualityWarnsOnSmallPhotos() {
        XCTAssertNotNil(PrintQuality.warning(pixelWidth: 400, pixelHeight: 400))
        XCTAssertNil(PrintQuality.warning(pixelWidth: 2000, pixelHeight: 2000))
    }

    func testNotificationPlannerCapsTheWeekAndSoftensMemorials() {
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)) ?? .now
        let birthday = calendar.date(from: DateComponents(year: 2020, month: 6, day: 20))
        let planned = NotificationPlanner.plan(
            pets: [("Bella", birthday, nil, true)],
            now: now,
            calendar: calendar,
            alreadyThisWeek: 0
        )
        XCTAssertLessThanOrEqual(planned.count, NotificationPlanner.weeklyCap)
        XCTAssertFalse(planned.contains { $0.isPlayful && $0.title.contains("Bella") })
        let full = NotificationPlanner.plan(
            pets: [("Bella", birthday, nil, false)],
            now: now,
            calendar: calendar,
            alreadyThisWeek: 3
        )
        XCTAssertTrue(full.isEmpty)
    }

    func testFamilyCodeUsesThePetName() {
        let code = FamilySharing.makeCode(for: "Bella")
        XCTAssertTrue(code.hasPrefix("BELL-"))
    }
}
