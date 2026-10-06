import SwiftUI
import UIKit

struct AssetThumbnail: View {
    var localIdentifier: String
    var side: CGFloat = 180
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            PawColor.coralSoft
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(PawColor.primary)
            }
        }
        .task(id: localIdentifier) {
            image = await ThumbnailLoader.shared.image(for: localIdentifier, side: side)
        }
    }
}
