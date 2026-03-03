import AVFoundation
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum VideoToGIFEnginePreference: String, CaseIterable, Identifiable {
    case auto
    case native
    case ffmpeg

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auto:
            return "Auto (native first)"
        case .native:
            return "Native (AVFoundation)"
        case .ffmpeg:
            return "ffmpeg"
        }
    }
}

enum VideoToGIFEngineUsed {
    case native
    case ffmpeg

    var title: String {
        switch self {
        case .native:
            return "Native (AVFoundation)"
        case .ffmpeg:
            return "ffmpeg"
        }
    }
}

struct GIFConversionSettings {
    let fps: Int
    let maxDimension: Int
}

struct GIFConversionResult {
    let outputURL: URL
    let engineUsed: VideoToGIFEngineUsed
}

enum GIFConversionError: LocalizedError {
    case invalidFPS
    case invalidScale
    case invalidVideo
    case noVideoTrack
    case unsupportedDuration
    case unableToCreateDestination
    case nativeFrameGenerationFailed(frame: Int)
    case unableToFinalize
    case ffmpegNotInstalled
    case ffmpegFailed(details: String)
    case nativeThenFFmpegFailed(native: Error, ffmpeg: Error)

    var errorDescription: String? {
        switch self {
        case .invalidFPS:
            return "Invalid FPS value."
        case .invalidScale:
            return "Invalid output scale value."
        case .invalidVideo:
            return "Could not read the selected video."
        case .noVideoTrack:
            return "No video track was found in the selected file."
        case .unsupportedDuration:
            return "Video duration is invalid or unsupported."
        case .unableToCreateDestination:
            return "Unable to create GIF output file."
        case .nativeFrameGenerationFailed(let frame):
            return "Native conversion failed while reading frame \(frame + 1)."
        case .unableToFinalize:
            return "Unable to finalize GIF output."
        case .ffmpegNotInstalled:
            return "ffmpeg is not installed. Use the install button to add it via Homebrew."
        case .ffmpegFailed(let details):
            return "ffmpeg conversion failed. \(details)"
        case .nativeThenFFmpegFailed(let native, let ffmpeg):
            return "Native conversion failed (\(native.localizedDescription)). ffmpeg fallback also failed (\(ffmpeg.localizedDescription))."
        }
    }
}

enum VideoToGIFConverter {
    static func convert(
        videoURL: URL,
        saveDirectory: URL,
        settings: GIFConversionSettings,
        preference: VideoToGIFEnginePreference
    ) async throws -> GIFConversionResult {
        guard settings.fps > 0 else {
            throw GIFConversionError.invalidFPS
        }

        guard settings.maxDimension > 0 else {
            throw GIFConversionError.invalidScale
        }

        let outputURL = suggestedOutputURL(for: videoURL, in: saveDirectory)

        switch preference {
        case .native:
            try await convertNative(videoURL: videoURL, outputURL: outputURL, settings: settings)
            return GIFConversionResult(outputURL: outputURL, engineUsed: .native)
        case .ffmpeg:
            try convertFFmpeg(videoURL: videoURL, outputURL: outputURL, settings: settings)
            return GIFConversionResult(outputURL: outputURL, engineUsed: .ffmpeg)
        case .auto:
            do {
                try await convertNative(videoURL: videoURL, outputURL: outputURL, settings: settings)
                return GIFConversionResult(outputURL: outputURL, engineUsed: .native)
            } catch let nativeError {
                do {
                    try convertFFmpeg(videoURL: videoURL, outputURL: outputURL, settings: settings)
                    return GIFConversionResult(outputURL: outputURL, engineUsed: .ffmpeg)
                } catch let ffmpegError {
                    throw GIFConversionError.nativeThenFFmpegFailed(native: nativeError, ffmpeg: ffmpegError)
                }
            }
        }
    }

    static func suggestedOutputURL(for videoURL: URL, in directory: URL) -> URL {
        let baseName = videoURL.deletingPathExtension().lastPathComponent
        let fileManager = FileManager.default

        var suffix = 0
        while true {
            let candidateName = suffix == 0 ? "\(baseName).gif" : "\(baseName)-\(suffix).gif"
            let candidate = directory.appendingPathComponent(candidateName)

            if !fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }

            suffix += 1
        }
    }

    static func ffmpegExecutableURL() -> URL? {
        let knownLocations = [
            "/opt/homebrew/bin/ffmpeg",
            "/usr/local/bin/ffmpeg",
            "/usr/bin/ffmpeg"
        ]

        for path in knownLocations where FileManager.default.isExecutableFile(atPath: path) {
            return URL(fileURLWithPath: path)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["ffmpeg"]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        guard process.terminationStatus == 0 else {
            return nil
        }

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        guard let rawPath = String(data: outputData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !rawPath.isEmpty,
            FileManager.default.isExecutableFile(atPath: rawPath)
        else {
            return nil
        }

        return URL(fileURLWithPath: rawPath)
    }

    private static func convertNative(videoURL: URL, outputURL: URL, settings: GIFConversionSettings) async throws {
        let asset = AVURLAsset(url: videoURL)

        let duration: CMTime
        let track: AVAssetTrack

        do {
            duration = try await asset.load(.duration)
            let tracks = try await asset.loadTracks(withMediaType: .video)
            guard let firstTrack = tracks.first else {
                throw GIFConversionError.noVideoTrack
            }
            track = firstTrack
        } catch let error as GIFConversionError {
            throw error
        } catch {
            throw GIFConversionError.invalidVideo
        }

        let durationSeconds = CMTimeGetSeconds(duration)
        guard durationSeconds.isFinite, durationSeconds > 0 else {
            throw GIFConversionError.unsupportedDuration
        }

        let naturalSize = try await track.load(.naturalSize)
        let preferredTransform = try await track.load(.preferredTransform)
        let oriented = naturalSize.applying(preferredTransform)
        let sourceSize = CGSize(width: abs(oriented.width), height: abs(oriented.height))

        let targetSize = scaledSize(from: sourceSize, maxDimension: settings.maxDimension)
        let delay = 1.0 / Double(settings.fps)

        let frameCount = max(1, Int((durationSeconds * Double(settings.fps)).rounded(.down)))
        let safeDuration = max(0, durationSeconds - 0.001)

        guard let destination = CGImageDestinationCreateWithURL(
            outputURL as CFURL,
            UTType.gif.identifier as CFString,
            frameCount,
            nil
        ) else {
            throw GIFConversionError.unableToCreateDestination
        }

        let gifProperties: [CFString: Any] = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFLoopCount: 0
            ]
        ]
        CGImageDestinationSetProperties(destination, gifProperties as CFDictionary)

        let frameProperties: [CFString: Any] = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFDelayTime: delay
            ]
        ]

        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        for frameIndex in 0..<frameCount {
            let frameTimeSeconds = min(safeDuration, Double(frameIndex) / Double(settings.fps))
            let frameTime = CMTime(seconds: frameTimeSeconds, preferredTimescale: 600)

            let cgImage: CGImage
            do {
                cgImage = try imageGenerator.copyCGImage(at: frameTime, actualTime: nil)
            } catch {
                throw GIFConversionError.nativeFrameGenerationFailed(frame: frameIndex)
            }

            let scaled = try resize(image: cgImage, to: targetSize)
            CGImageDestinationAddImage(destination, scaled, frameProperties as CFDictionary)
        }

        guard CGImageDestinationFinalize(destination) else {
            throw GIFConversionError.unableToFinalize
        }
    }

    private static func convertFFmpeg(videoURL: URL, outputURL: URL, settings: GIFConversionSettings) throws {
        guard let ffmpegURL = ffmpegExecutableURL() else {
            throw GIFConversionError.ffmpegNotInstalled
        }

        let process = Process()
        process.executableURL = ffmpegURL
        process.arguments = [
            "-y",
            "-i", videoURL.path,
            "-vf", "fps=\(settings.fps),scale=\(settings.maxDimension):-1:flags=lanczos",
            outputURL.path
        ]

        let errorPipe = Pipe()
        process.standardOutput = Pipe()
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let details = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown ffmpeg error"
            throw GIFConversionError.ffmpegFailed(details: details)
        }
    }

    private static func scaledSize(from sourceSize: CGSize, maxDimension: Int) -> CGSize {
        let longestEdge = max(sourceSize.width, sourceSize.height)
        guard longestEdge > 0 else {
            return CGSize(width: maxDimension, height: maxDimension)
        }

        let scaleFactor = CGFloat(maxDimension) / longestEdge
        let width = max(1, Int((sourceSize.width * scaleFactor).rounded()))
        let height = max(1, Int((sourceSize.height * scaleFactor).rounded()))
        return CGSize(width: width, height: height)
    }

    private static func resize(image: CGImage, to size: CGSize) throws -> CGImage {
        let width = max(1, Int(size.width.rounded()))
        let height = max(1, Int(size.height.rounded()))

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw GIFConversionError.unableToFinalize
        }

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(origin: .zero, size: CGSize(width: width, height: height)))

        guard let resized = context.makeImage() else {
            throw GIFConversionError.unableToFinalize
        }

        return resized
    }
}
