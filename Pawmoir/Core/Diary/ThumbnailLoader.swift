import Photos
import UIKit

/// Small cached thumbnails for the diary grid. The full asset stays in Photos.
@MainActor
final class ThumbnailLoader {
    static let shared = ThumbnailLoader()

    private let manager = PHCachingImageManager()
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 400
        manager.allowsCachingHighQualityImages = false
    }

    func image(for localIdentifier: String, side: CGFloat) async -> UIImage? {
        let key = "\(localIdentifier)-\(Int(side))" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        guard let asset = assets.firstObject else { return nil }
        let scale = UIScreen.main.scale
        let target = CGSize(width: side * scale, height: side * scale)
        let image: UIImage? = await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true
            var resumed = false
            self.manager.requestImage(for: asset, targetSize: target, contentMode: .aspectFill, options: options) { image, info in
                let cancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
                if resumed { return }
                resumed = true
                continuation.resume(returning: cancelled ? nil : image)
            }
        }
        if let image {
            cache.setObject(image, forKey: key)
        }
        return image
    }
}
