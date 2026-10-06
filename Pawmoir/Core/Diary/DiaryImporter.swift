import Foundation
import SwiftData

/// Writes scan hits into the diary without copying image files.
@MainActor
enum DiaryImporter {
    static func importHits(_ hits: [ScanHit], pets: [Pet], into context: ModelContext) {
        let petsByID = Dictionary(uniqueKeysWithValues: pets.map { ($0.id, $0) })
        for hit in hits where hit.isBestOfBurst && !hit.albumTags.contains("blurry") {
            guard let petID = hit.petID, let pet = petsByID[petID] else { continue }
            let entry = MemoryEntry(
                assetLocalIdentifier: hit.assetID,
                date: hit.date,
                note: "",
                pets: [pet],
                sharpnessScore: hit.sharpness,
                isBestOfBurst: true,
                needsConfirmation: hit.needsConfirmation,
                albumTags: hit.albumTags,
                burstIdentifier: hit.burstIdentifier
            )
            context.insert(entry)
            if pet.featurePrintData == nil, let print = hit.featurePrint, !hit.needsConfirmation {
                pet.featurePrintData = print
            }
        }
        try? context.save()
    }
}
