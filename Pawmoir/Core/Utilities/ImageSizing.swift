import UIKit

/// Shrinks a profile photo before it is stored on the pet.
enum ImageSizing {
    @MainActor
    static func jpegThumbnail(from data: Data, maxPixel: CGFloat = 512, quality: CGFloat = 0.82) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let longest = max(image.size.width, image.size.height)
        guard longest > 0 else { return nil }
        let scale = min(1, maxPixel / longest)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let rendered = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return rendered.jpegData(compressionQuality: quality)
    }
}
