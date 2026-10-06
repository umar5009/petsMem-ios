import XCTest

final class OnboardingUITests: XCTestCase {
    func testOnboardingCanBeSkippedThroughToTheDiary() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        let begin = app.buttons["onboarding.welcome.begin"]
        XCTAssertTrue(begin.waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Every pawprint deserves to be remembered"].exists)
        begin.tap()

        let name = app.textFields["onboarding.pet.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Bella")
        app.buttons["onboarding.pet.continue"].tap()

        let skipPhotos = app.buttons["onboarding.photos.skip"]
        XCTAssertTrue(skipPhotos.waitForExistence(timeout: 5))
        skipPhotos.tap()

        let magic = app.buttons["onboarding.magic.continue"]
        XCTAssertTrue(magic.waitForExistence(timeout: 5))
        magic.tap()

        let recap = app.buttons["onboarding.recap.continue"]
        XCTAssertTrue(recap.waitForExistence(timeout: 5))
        recap.tap()

        let later = app.buttons["onboarding.paywall.skip"]
        XCTAssertTrue(later.waitForExistence(timeout: 5))
        later.tap()

        let notNow = app.buttons["onboarding.notifications.skip"]
        XCTAssertTrue(notNow.waitForExistence(timeout: 5))
        notNow.tap()

        XCTAssertTrue(app.tabBars.buttons["Diary"].waitForExistence(timeout: 8))
    }
}
