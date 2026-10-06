import XCTest
import SwiftData
@testable import Pawmoir

final class ServiceTests: XCTestCase {
    func testMockCaptionsIncludeThePetName() async throws {
        let lines = try await MockAIService().captions(
            for: CaptionRequest(
                petName: "Bella",
                species: .dog,
                personalityTags: ["Drama queen"],
                tone: .sassy
            )
        )
        XCTAssertEqual(lines.count, 5)
        XCTAssertTrue(lines.allSatisfy { $0.contains("Bella") })
    }

    func testPremiumPrintQuoteIsFifteenPercentOff() async throws {
        let service = MockPrintService()
        let full = try await service.quote(for: .hardcoverBook, premium: false)
        let discounted = try await service.quote(for: .hardcoverBook, premium: true)
        XCTAssertEqual(full.amount, 39)
        XCTAssertEqual(discounted.amount, Decimal(string: "33.15"))
        XCTAssertTrue(discounted.premiumDiscountApplied)
        XCTAssertFalse(full.premiumDiscountApplied)
    }

    @MainActor
    func testQuickAddRequiresANoteThenSaves() throws {
        let container = try ModelContainerFactory.make(inMemory: true)
        let context = container.mainContext
        let pet = Pet(name: "Bella", species: .dog)
        context.insert(pet)

        let model = QuickAddViewModel()
        XCTAssertThrowsError(try model.save(pet: pet, context: context)) { error in
            XCTAssertEqual(error as? AppError, .validation("Write a note to save this memory."))
        }

        model.note = " She stole the sock. "
        model.mood = .playful
        model.location = "Kitchen"
        try model.save(pet: pet, context: context)

        let memories = try context.fetch(FetchDescriptor<MemoryEntry>())
        XCTAssertEqual(memories.count, 1)
        XCTAssertEqual(memories.first?.note, "She stole the sock.")
        XCTAssertEqual(memories.first?.mood, .playful)
        XCTAssertEqual(memories.first?.locationName, "Kitchen")
        XCTAssertEqual(memories.first?.pets.first?.name, "Bella")
    }
}
