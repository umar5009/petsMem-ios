import CoreGraphics
import Foundation

/// On-device decision for "which pet is this?"
///
/// Distances come from `VNFeaturePrintObservation`. Lower means more alike.
/// The thresholds are deliberately conservative so a wrong match can be corrected.
enum PetMatcher {
    /// Confident same-pet match.
    static let samePetDistance: Float = 0.55
    /// Still worth showing, but the person should confirm.
    static let possibleDistance: Float = 0.85

    struct Choice: Equatable, Sendable {
        var petID: UUID
        var distance: Float
    }

    static func choose(distances: [Choice]) -> (petID: UUID, needsConfirmation: Bool)? {
        let sorted = distances.sorted { $0.distance < $1.distance }
        guard let best = sorted.first, best.distance < possibleDistance else { return nil }
        let runnerUp = sorted.dropFirst().first
        let tooClose = runnerUp.map { $0.distance - best.distance < 0.12 } ?? false
        let uncertain = best.distance > samePetDistance || tooClose
        return (best.petID, uncertain)
    }
}

enum BurstPicker {
    struct Frame: Equatable, Sendable {
        var assetID: String
        var sharpness: Double
    }

    /// Keeps the crispest frame in a burst and marks the rest as extras.
    static func winnerID(in frames: [Frame]) -> String? {
        frames.max { $0.sharpness < $1.sharpness }?.assetID
    }
}

enum ImageSharpness {
    /// Average neighbor contrast on a tiny grayscale sample. Not a lab metric.
    static func score(of image: CGImage) -> Double {
        let width = 32
        let height = 32
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return 0 }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let data = context.data else { return 0 }
        let pixels = data.bindMemory(to: UInt8.self, capacity: width * height * 4)
        var total: Double = 0
        var count = 0
        for y in 0..<(height - 1) {
            for x in 0..<(width - 1) {
                let left = (y * width + x) * 4
                let right = left + 4
                total += Double(abs(Int(pixels[left]) - Int(pixels[right])))
                count += 1
            }
        }
        guard count > 0 else { return 0 }
        return total / Double(count)
    }

    static let blurryBelow = 6.0
}

enum SmartAlbum: String, CaseIterable, Identifiable, Sendable {
    case bestSmiles
    case sleepy
    case adventures
    case earlyDays
    case withFamily

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bestSmiles: "Best smiles"
        case .sleepy: "Sleepy"
        case .adventures: "Adventures"
        case .earlyDays: "Puppy & kitten days"
        case .withFamily: "With family"
        }
    }

    var symbolName: String {
        switch self {
        case .bestSmiles: "face.smiling"
        case .sleepy: "moon.fill"
        case .adventures: "map.fill"
        case .earlyDays: "pawprint.fill"
        case .withFamily: "person.2.fill"
        }
    }
}

enum AlbumTagger {
    static func tags(classifications: [String], anchor: Date?, photoDate: Date, calendar: Calendar = .current) -> [String] {
        let haystack = classifications.joined(separator: " ").lowercased()
        var tags: [String] = []
        if haystack.contains("smile") || haystack.contains("happy") || haystack.contains("grin") {
            tags.append(SmartAlbum.bestSmiles.rawValue)
        }
        if haystack.contains("sleep") || haystack.contains("bed") || haystack.contains("nap") || haystack.contains("couch") {
            tags.append(SmartAlbum.sleepy.rawValue)
        }
        if haystack.contains("outdoor") || haystack.contains("park") || haystack.contains("beach") || haystack.contains("mountain") || haystack.contains("hik") {
            tags.append(SmartAlbum.adventures.rawValue)
        }
        if haystack.contains("person") || haystack.contains("people") || haystack.contains("family") || haystack.contains("child") {
            tags.append(SmartAlbum.withFamily.rawValue)
        }
        if let anchor, let end = calendar.date(byAdding: .year, value: 1, to: anchor), photoDate <= end, photoDate >= anchor {
            tags.append(SmartAlbum.earlyDays.rawValue)
        }
        return tags
    }
}
