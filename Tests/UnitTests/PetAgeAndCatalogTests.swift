import XCTest
@testable import Pawmoir

final class PetAgeAndCatalogTests: XCTestCase {
    func testDogAndCatYearsFollowTheChart() {
        XCTAssertEqual(PetAgeCalculator.petYears(species: .dog, years: 2, months: 0, days: 0), 24)
        XCTAssertEqual(PetAgeCalculator.petYears(species: .dog, years: 4, months: 0, days: 0), 34)
        XCTAssertEqual(PetAgeCalculator.petYears(species: .cat, years: 4, months: 0, days: 0), 32)
        XCTAssertEqual(PetAgeCalculator.petYears(species: .dog, years: 0, months: 6, days: 0), 8)
        XCTAssertEqual(PetAgeCalculator.petYears(species: .other, years: 0, months: 0, days: 0), 0)
    }

    func testHumanAgeUsesBirthdayThenGotchaDay() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 15)))
        let birthday = try XCTUnwrap(calendar.date(from: DateComponents(year: 2024, month: 6, day: 15)))
        let gotcha = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 1, day: 15)))

        let fromBirthday = PetAgeCalculator.age(
            species: .dog,
            birthday: birthday,
            gotchaDay: gotcha,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(fromBirthday?.basis, .birthday)
        XCTAssertEqual(fromBirthday?.years, 2)
        XCTAssertEqual(fromBirthday?.humanSummary, "2 years")
        XCTAssertEqual(fromBirthday?.petYears, 24)

        let fromGotcha = PetAgeCalculator.age(
            species: .cat,
            birthday: nil,
            gotchaDay: gotcha,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(fromGotcha?.basis, .gotchaDay)
        XCTAssertEqual(fromGotcha?.months, 5)
        XCTAssertEqual(fromGotcha?.humanSummary, "5 months")
        XCTAssertNil(PetAgeCalculator.age(species: .dog, birthday: nil, gotchaDay: nil, now: now, calendar: calendar))
    }

    func testBreedSearchAndPaperSizeAndCalendarSeason() throws {
        XCTAssertEqual(BreedCatalog.suggestions(for: .dog, query: "gold"), ["Golden Retriever"])
        XCTAssertEqual(PaperStandard.preferred(locale: Locale(identifier: "en_US")), "Letter")
        XCTAssertEqual(PaperStandard.preferred(locale: Locale(identifier: "en_CA")), "Letter")
        XCTAssertEqual(PaperStandard.preferred(locale: Locale(identifier: "en_GB")), "A4")
        XCTAssertEqual(PaperStandard.preferred(locale: Locale(identifier: "en_AU")), "A4")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let october = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 5)))
        let march = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 3, day: 1)))
        XCTAssertEqual(SeasonalShop.calendarHeadline(now: october, calendar: calendar), "Make a 2027 calendar")
        XCTAssertNil(SeasonalShop.calendarHeadline(now: march, calendar: calendar))
    }
}
