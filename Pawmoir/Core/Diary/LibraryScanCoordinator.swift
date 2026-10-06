import BackgroundTasks
import Foundation
import SwiftData

/// Foreground scans stay short. A background processing task continues later.
enum LibraryScanCoordinator {
    static let taskID = "com.pawmoir.app.library-scan"
    private static var didRegister = false

    static func register(container: ModelContainer) {
        guard !didRegister else { return }
        didRegister = true
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskID, using: nil) { task in
            guard let processing = task as? BGProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }
            let work = Task {
                await runBackgroundScan(container: container)
                processing.setTaskCompleted(success: true)
            }
            processing.expirationHandler = {
                work.cancel()
                processing.setTaskCompleted(success: false)
            }
        }
    }

    static func schedule() {
        let request = BGProcessingTaskRequest(identifier: taskID)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func runBackgroundScan(container: ModelContainer) async {
        let context = ModelContext(container)
        let pets = (try? context.fetch(FetchDescriptor<Pet>())) ?? []
        let existing = (try? context.fetch(FetchDescriptor<MemoryEntry>())) ?? []
        let known = Set(existing.compactMap(\.assetLocalIdentifier))
        let profiles = pets.map {
            PetScanProfile(id: $0.id, species: $0.species, anchor: $0.ageAnchor, featurePrint: $0.featurePrintData)
        }
        let hits = await PhotoLibraryScanner().scan(pets: profiles, existingIDs: known, limit: 600) { _ in }
        await MainActor.run {
            DiaryImporter.importHits(hits, pets: pets, into: context)
        }
    }
}
