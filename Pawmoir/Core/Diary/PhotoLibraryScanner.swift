import CoreGraphics
import Foundation
import Photos
import Vision

/// A pet the scanner can compare without holding a SwiftData model.
struct PetScanProfile: Sendable {
    var id: UUID
    var species: PetSpecies
    var anchor: Date?
    var featurePrint: Data?
}

struct ScanHit: Sendable, Identifiable {
    var id: String { assetID }
    var assetID: String
    var date: Date
    var isVideo: Bool
    var petID: UUID?
    var needsConfirmation: Bool
    var sharpness: Double
    var isBestOfBurst: Bool
    var albumTags: [String]
    var featurePrint: Data?
    var burstIdentifier: String
    var pixelWidth: Int
    var pixelHeight: Int
}

/// Walks the photos the person allowed, on device, and keeps only likely pet shots.
///
/// Image bytes are requested as small thumbnails and are not written into the diary.
/// The diary stores the PhotoKit identifier.
final class PhotoLibraryScanner: Sendable {
    func scan(
        pets: [PetScanProfile],
        existingIDs: Set<String>,
        limit: Int,
        onProgress: @Sendable (Double) -> Void
    ) async -> [ScanHit] {
        let summaries = await assetSummaries(limit: limit, skipping: existingIDs)
        guard !summaries.isEmpty else {
            onProgress(1)
            return []
        }
        var hits: [ScanHit] = []
        for (index, summary) in summaries.enumerated() {
            if Task.isCancelled { break }
            if let hit = await analyze(summary, pets: pets) {
                hits.append(hit)
            }
            onProgress(Double(index + 1) / Double(summaries.count))
        }
        return markBursts(hits)
    }

    private func assetSummaries(limit: Int, skipping existing: Set<String>) async -> [AssetSummary] {
        await MainActor.run {
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            options.fetchLimit = limit
            let fetched = PHAsset.fetchAssets(with: options)
            var items: [AssetSummary] = []
            fetched.enumerateObjects { asset, _, stop in
                if items.count >= limit {
                    stop.pointee = true
                    return
                }
                guard !existing.contains(asset.localIdentifier) else { return }
                items.append(
                    AssetSummary(
                        id: asset.localIdentifier,
                        date: asset.creationDate ?? .now,
                        isVideo: asset.mediaType == .video,
                        burstIdentifier: asset.burstIdentifier ?? "",
                        pixelWidth: asset.pixelWidth,
                        pixelHeight: asset.pixelHeight
                    )
                )
            }
            return items
        }
    }

    private func analyze(_ summary: AssetSummary, pets: [PetScanProfile]) async -> ScanHit? {
        guard let image = await thumbnail(for: summary.id) else { return nil }
        let vision = VisionRead.read(image)
        guard vision.hasPet else { return nil }
        let sharpness = ImageSharpness.score(of: image)
        let species: PetSpecies = vision.sawCat && !vision.sawDog ? .cat : (vision.sawDog && !vision.sawCat ? .dog : .other)
        let candidates = pets.filter { $0.species == species || species == .other || $0.species == .other }
        let chosen = match(candidates, print: vision.featurePrint)
        let anchor = candidates.first { $0.id == chosen?.petID }?.anchor
        var tags = AlbumTagger.tags(classifications: vision.labels, anchor: anchor, photoDate: summary.date)
        if sharpness < ImageSharpness.blurryBelow {
            tags.append("blurry")
        }
        return ScanHit(
            assetID: summary.id,
            date: summary.date,
            isVideo: summary.isVideo,
            petID: chosen?.petID,
            needsConfirmation: chosen?.needsConfirmation ?? (candidates.count > 1),
            sharpness: sharpness,
            isBestOfBurst: true,
            albumTags: tags,
            featurePrint: vision.archivedPrint,
            burstIdentifier: summary.burstIdentifier,
            pixelWidth: summary.pixelWidth,
            pixelHeight: summary.pixelHeight
        )
    }

    private func match(_ pets: [PetScanProfile], print: VNFeaturePrintObservation?) -> (petID: UUID, needsConfirmation: Bool)? {
        guard !pets.isEmpty else { return nil }
        if pets.count == 1, let only = pets.first {
            return (only.id, false)
        }
        guard let print else {
            return pets.first.map { ($0.id, true) }
        }
        var choices: [PetMatcher.Choice] = []
        for pet in pets {
            guard let data = pet.featurePrint, let stored = FeaturePrintBox.unarchive(data) else { continue }
            var distance: Float = 0
            if (try? print.computeDistance(&distance, to: stored)) != nil {
                choices.append(PetMatcher.Choice(petID: pet.id, distance: distance))
            }
        }
        if let choice = PetMatcher.choose(distances: choices) {
            return choice
        }
        return pets.first.map { ($0.id, true) }
    }

    private func markBursts(_ hits: [ScanHit]) -> [ScanHit] {
        let groups = Dictionary(grouping: hits) { hit -> String in
            hit.burstIdentifier.isEmpty ? hit.assetID : hit.burstIdentifier
        }
        var winners = Set<String>()
        for (_, group) in groups {
            let frames = group.map { BurstPicker.Frame(assetID: $0.assetID, sharpness: $0.sharpness) }
            if let winner = BurstPicker.winnerID(in: frames) {
                winners.insert(winner)
            }
        }
        return hits.map { hit in
            var copy = hit
            let key = hit.burstIdentifier.isEmpty ? hit.assetID : hit.burstIdentifier
            let groupSize = groups[key]?.count ?? 1
            copy.isBestOfBurst = groupSize == 1 || winners.contains(hit.assetID)
            return copy
        }
    }

    private func thumbnail(for localID: String) async -> CGImage? {
        await Task.detached(priority: .utility) {
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localID], options: nil)
            guard let asset = assets.firstObject else { return nil }
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            options.deliveryMode = .fastFormat
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = false
            var image: CGImage?
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 256, height: 256),
                contentMode: .aspectFill,
                options: options
            ) { result, _ in
                image = result?.cgImage
            }
            return image
        }.value
    }
}

private struct AssetSummary: Sendable {
    var id: String
    var date: Date
    var isVideo: Bool
    var burstIdentifier: String
    var pixelWidth: Int
    var pixelHeight: Int
}

private struct VisionRead {
    var sawDog: Bool
    var sawCat: Bool
    var labels: [String]
    var featurePrint: VNFeaturePrintObservation?
    var archivedPrint: Data?

    var hasPet: Bool { sawDog || sawCat }

    static func read(_ image: CGImage) -> VisionRead {
        let animals = VNRecognizeAnimalsRequest()
        let feature = VNGenerateImageFeaturePrintRequest()
        let classify = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try? handler.perform([animals, feature, classify])
        let animalResults = animals.results as? [VNRecognizedObjectObservation] ?? []
        let animalLabels = animalResults.flatMap(\.labels).map(\.identifier)
        let sceneResults = classify.results as? [VNClassificationObservation] ?? []
        let sceneLabels = sceneResults.prefix(8).map(\.identifier)
        let print = feature.results?.first as? VNFeaturePrintObservation
        return VisionRead(
            sawDog: animalLabels.contains("Dog"),
            sawCat: animalLabels.contains("Cat"),
            labels: animalLabels + sceneLabels,
            featurePrint: print,
            archivedPrint: print.flatMap(FeaturePrintBox.archive)
        )
    }
}

enum FeaturePrintBox {
    static func archive(_ observation: VNFeaturePrintObservation) -> Data? {
        try? NSKeyedArchiver.archivedData(withRootObject: observation, requiringSecureCoding: true)
    }

    static func unarchive(_ data: Data) -> VNFeaturePrintObservation? {
        try? NSKeyedUnarchiver.unarchivedObject(ofClass: VNFeaturePrintObservation.self, from: data)
    }
}
