import Foundation
import SwiftData

enum ModelContainerFactory {
    /// CloudKit is used only when Premium asked for it. A missing entitlement falls back to the local store.
    static func make(inMemory: Bool = false, cloudKit: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            Pet.self,
            MemoryEntry.self,
            Milestone.self,
            Creation.self,
            PrintOrder.self
        ])
        if cloudKit, !inMemory {
            let cloud = ModelConfiguration(
                "Pawmoir",
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            if let container = try? ModelContainer(for: schema, configurations: [cloud]) {
                return container
            }
        }
        let configuration = ModelConfiguration(
            "Pawmoir",
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
