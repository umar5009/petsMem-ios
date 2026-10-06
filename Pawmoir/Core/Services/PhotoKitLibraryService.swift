import Foundation
import Photos
import UIKit

/// Reads authorization and a metadata count. It does not request image data.
final class PhotoKitLibraryService: PhotoLibraryService, @unchecked Sendable {
    func authorizationStatus() -> PhotoAuthorization {
        PhotoAuthorization(status: PHPhotoLibrary.authorizationStatus(for: .readWrite))
    }

    func requestAccess() async -> PhotoAuthorization {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        return PhotoAuthorization(status: status)
    }

    func mediaCount() async -> Int {
        let status = authorizationStatus()
        guard status.canReadLibrary else { return 0 }
        return await MainActor.run {
            let images = PHAsset.fetchAssets(with: .image, options: nil).count
            let videos = PHAsset.fetchAssets(with: .video, options: nil).count
            return images + videos
        }
    }

    /// Limited Photo Access: let the person add or remove the photos we can see.
    @MainActor
    static func presentLimitedPicker() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
            ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first
        else { return }

        let root = scene.windows.first(where: \.isKeyWindow)?.rootViewController
            ?? scene.windows.first?.rootViewController
        guard let presenter = root?.presentedViewController ?? root else { return }
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: presenter)
    }
}

extension PhotoAuthorization {
    init(status: PHAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .restricted:
            self = .restricted
        case .denied:
            self = .denied
        case .authorized:
            self = .authorized
        case .limited:
            self = .limited
        @unknown default:
            self = .denied
        }
    }
}

final class PreviewPhotoLibraryService: PhotoLibraryService, @unchecked Sendable {
    var status: PhotoAuthorization
    var count: Int

    init(status: PhotoAuthorization, imageCount: Int) {
        self.status = status
        self.count = imageCount
    }

    func authorizationStatus() -> PhotoAuthorization { status }

    func requestAccess() async -> PhotoAuthorization {
        if status == .notDetermined {
            status = .authorized
        }
        return status
    }

    func mediaCount() async -> Int {
        status.canReadLibrary ? count : 0
    }
}
