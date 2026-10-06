import AVFoundation
import CoreVideo
import UIKit

enum SlideshowExportError: LocalizedError {
    case noSlides
    case writer(String)

    var errorDescription: String? {
        switch self {
        case .noSlides:
            "Pick at least one photo."
        case .writer(let message):
            message
        }
    }
}

/// Builds a 1080p slideshow from stills, an original tone, and an optional watermark.
enum SlideshowExporter {
    static func export(
        images: [UIImage],
        title: String,
        subtitle: String,
        aspect: ExportAspect,
        track: MusicTrack,
        watermark: Bool,
        onProgress: @Sendable (Double) -> Void
    ) async throws -> URL {
        let slides = images.isEmpty ? [placeholder(title: title, size: aspect.pixelSize)] : images
        let size = aspect.pixelSize
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("pawmoir-\(UUID().uuidString).mp4")
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }

        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(size.width),
            AVVideoHeightKey: Int(size.height)
        ]
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput.expectsMediaDataInRealTime = false
        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: Int(size.width),
            kCVPixelBufferHeightKey as String: Int(size.height)
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: attributes)
        let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings())
        guard writer.canAdd(videoInput), writer.canAdd(audioInput) else {
            throw SlideshowExportError.writer("This device couldn't start a video export.")
        }
        writer.add(videoInput)
        writer.add(audioInput)
        guard writer.startWriting() else {
            throw SlideshowExportError.writer(writer.error?.localizedDescription ?? "Export didn't start.")
        }
        writer.startSession(atSourceTime: .zero)

        let fps: Int32 = 30
        let framesPerSlide = fps * 2
        let totalFrames = framesPerSlide * Int32(slides.count)
        var frameIndex: Int32 = 0
        for (slideIndex, image) in slides.enumerated() {
            let rendered = render(
                image: image,
                title: slideIndex == 0 ? title : "",
                subtitle: slideIndex == 0 ? subtitle : "",
                size: size,
                watermark: watermark
            )
            guard let buffer = pixelBuffer(from: rendered, adaptor: adaptor) else { continue }
            for _ in 0..<framesPerSlide {
                if Task.isCancelled { throw CancellationError() }
                while !videoInput.isReadyForMoreMediaData {
                    try await Task.sleep(for: .milliseconds(10))
                }
                let time = CMTime(value: CMTimeValue(frameIndex), timescale: fps)
                adaptor.append(buffer, withPresentationTime: time)
                frameIndex += 1
                onProgress(Double(frameIndex) / Double(max(totalFrames, 1)) * 0.85)
            }
        }
        videoInput.markAsFinished()

        let duration = Double(totalFrames) / Double(fps)
        try appendTone(frequency: track.frequency, duration: duration, input: audioInput, sampleRate: 44_100)
        audioInput.markAsFinished()
        onProgress(0.95)
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            writer.finishWriting {
                continuation.resume()
            }
        }
        if writer.status != .completed {
            throw SlideshowExportError.writer(writer.error?.localizedDescription ?? "Export didn't finish.")
        }
        onProgress(1)
        return url
    }

    static func still(
        image: UIImage?,
        text: String,
        aspect: ExportAspect,
        watermark: Bool
    ) -> UIImage {
        let base = image ?? placeholder(title: text, size: aspect.pixelSize)
        return render(image: base, title: "", subtitle: text, size: aspect.pixelSize, watermark: watermark)
    }

    private static func render(image: UIImage, title: String, subtitle: String, size: CGSize, watermark: Bool) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            UIColor(red: 0.17, green: 0.16, blue: 0.15, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            let fitted = aspectFit(image.size, in: size)
            image.draw(in: fitted)
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            if !title.isEmpty {
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: size.width * 0.07, weight: .bold),
                    .foregroundColor: UIColor.white,
                    .paragraphStyle: paragraph
                ]
                let rect = CGRect(x: 40, y: size.height * 0.08, width: size.width - 80, height: 120)
                title.draw(in: rect, withAttributes: attributes)
            }
            if !subtitle.isEmpty {
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: size.width * 0.045, weight: .semibold),
                    .foregroundColor: UIColor.white,
                    .paragraphStyle: paragraph
                ]
                let rect = CGRect(x: 48, y: size.height * 0.78, width: size.width - 96, height: 220)
                subtitle.draw(in: rect, withAttributes: attributes)
            }
            if watermark {
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 28, weight: .semibold),
                    .foregroundColor: UIColor.white.withAlphaComponent(0.9)
                ]
                let text = ExportPolicy.watermarkText
                let rect = CGRect(x: 36, y: size.height - 72, width: size.width - 72, height: 40)
                text.draw(in: rect, withAttributes: attributes)
            }
        }
    }

    private static func placeholder(title: String, size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            UIColor(red: 0.88, green: 0.48, blue: 0.37, alpha: 1).setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 64, weight: .bold),
                .foregroundColor: UIColor(red: 0.17, green: 0.16, blue: 0.14, alpha: 1)
            ]
            title.draw(at: CGPoint(x: 48, y: size.height / 2), withAttributes: attributes)
        }
    }

    private static func aspectFit(_ image: CGSize, in canvas: CGSize) -> CGRect {
        guard image.width > 0, image.height > 0 else {
            return CGRect(origin: .zero, size: canvas)
        }
        let scale = min(canvas.width / image.width, canvas.height / image.height)
        let fitted = CGSize(width: image.width * scale, height: image.height * scale)
        return CGRect(
            x: (canvas.width - fitted.width) / 2,
            y: (canvas.height - fitted.height) / 2,
            width: fitted.width,
            height: fitted.height
        )
    }

    private static func pixelBuffer(from image: UIImage, adaptor: AVAssetWriterInputPixelBufferAdaptor) -> CVPixelBuffer? {
        guard let pool = adaptor.pixelBufferPool else { return nil }
        var buffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer)
        guard status == kCVReturnSuccess, let buffer else { return nil }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: CVPixelBufferGetWidth(buffer),
            height: CVPixelBufferGetHeight(buffer),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ), let cgImage = image.cgImage else { return nil }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(CVPixelBufferGetWidth(buffer)), height: CGFloat(CVPixelBufferGetHeight(buffer))))
        return buffer
    }

    private static func audioSettings() -> [String: Any] {
        [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: 1,
            AVSampleRateKey: 44_100,
            AVEncoderBitRateKey: 64_000
        ]
    }

    private static func appendTone(frequency: Double, duration: Double, input: AVAssetWriterInput, sampleRate: Double) throws {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        guard let format else { return }
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        guard let samples = buffer.floatChannelData?[0] else { return }
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let envelope = min(1, time * 4) * min(1, (duration - time) * 4)
            samples[frame] = Float(sin(2 * Double.pi * frequency * time) * 0.08 * envelope)
        }
        let converter = AVAudioConverter(from: format, to: AVAudioFormat(settings: audioSettings()) ?? format)
        // AAC input wants CMSampleBuffer. Write PCM via a simple sample buffer.
        _ = converter
        guard let sampleBuffer = sampleBuffer(from: buffer, sampleRate: sampleRate) else { return }
        while !input.isReadyForMoreMediaData {
            Thread.sleep(forTimeInterval: 0.01)
        }
        input.append(sampleBuffer)
    }

    private static func sampleBuffer(from buffer: AVAudioPCMBuffer, sampleRate: Double) -> CMSampleBuffer? {
        var asbd = buffer.format.streamDescription.pointee
        var formatDescription: CMAudioFormatDescription?
        guard CMAudioFormatDescriptionCreate(allocator: kCFAllocatorDefault, asbd: &asbd, layoutSize: 0, layout: nil, magicCookieSize: 0, magicCookie: nil, extensions: nil, formatDescriptionOut: &formatDescription) == noErr,
              let formatDescription else { return nil }
        var timing = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: CMTimeScale(sampleRate)),
            presentationTimeStamp: .zero,
            decodeTimeStamp: .invalid
        )
        var sampleBuffer: CMSampleBuffer?
        guard let channel = buffer.floatChannelData?[0] else { return nil }
        var block: CMBlockBuffer?
        let byteCount = Int(buffer.frameLength) * MemoryLayout<Float>.size
        guard CMBlockBufferCreateWithMemoryBlock(
            allocator: kCFAllocatorDefault,
            memoryBlock: nil,
            blockLength: byteCount,
            blockAllocator: nil,
            customBlockSource: nil,
            offsetToData: 0,
            dataLength: byteCount,
            flags: 0,
            blockBufferOut: &block
        ) == kCMBlockBufferNoErr, let block else { return nil }
        guard CMBlockBufferReplaceDataBytes(with: channel, blockBuffer: block, offsetIntoDestination: 0, dataLength: byteCount) == kCMBlockBufferNoErr else {
            return nil
        }
        guard CMSampleBufferCreate(
            allocator: kCFAllocatorDefault,
            dataBuffer: block,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: formatDescription,
            sampleCount: CMItemCount(buffer.frameLength),
            sampleTimingEntryCount: 1,
            sampleTimingArray: &timing,
            sampleSizeEntryCount: 0,
            sampleSizeArray: nil,
            sampleBufferOut: &sampleBuffer
        ) == noErr else { return nil }
        return sampleBuffer
    }
}
