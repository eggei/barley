import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct VideoToGIFFeatureView: View {
    private static let recentOutputPathsKey = "videoToGIF.recentOutputPaths"

    private enum FPSOption: Int, CaseIterable, Identifiable {
        case eight = 8
        case twelve = 12
        case fifteen = 15
        case twentyFour = 24

        var id: Int { rawValue }

        var title: String {
            "\(rawValue) fps"
        }
    }

    private enum ScaleOption: Int, CaseIterable, Identifiable {
        case px720 = 720
        case px960 = 960
        case px1200 = 1200
        case px1600 = 1600

        var id: Int { rawValue }

        var title: String {
            "\(rawValue)px long edge"
        }
    }

    @State private var selectedVideoURL: URL?
    @State private var saveDirectoryPath: String = defaultSaveDirectoryPath()
    @State private var selectedFPS: FPSOption = .twelve
    @State private var selectedScale: ScaleOption = .px1200
    @State private var recentOutputURLs: [URL] = []
    @State private var statusMessage: String?
    @State private var errorMessage: String?
    @State private var ffmpegInstalled: Bool = VideoToGIFConverter.ffmpegExecutableURL() != nil
    @State private var isConverting = false
    @State private var conversionTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Video to GIF")
                    .font(.title3.weight(.semibold))
                Text("Convert MOV or MP4 videos into GIF files locally on your Mac.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            videoSelection
            saveLocation
            controls
            privacyAndFFmpegNote
            actions

            if let statusMessage {
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if isConverting {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Converting video to GIF...")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            recentOutputs

            Spacer(minLength: 0)
        }
        .onAppear {
            ffmpegInstalled = VideoToGIFConverter.ffmpegExecutableURL() != nil
            loadRecentOutputs()
        }
    }

    private var videoSelection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Source Video")
                .font(.callout.weight(.medium))

            HStack(spacing: 8) {
                Text(selectedVideoURL?.path ?? "No video selected")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(selectedVideoURL == nil ? .secondary : .primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button("Choose Video") {
                    pickVideo()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var saveLocation: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Save Location")
                .font(.callout.weight(.medium))

            HStack(spacing: 8) {
                TextField("/Users/you/Desktop", text: $saveDirectoryPath)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.caption, design: .monospaced))

                Button("Browse") {
                    pickSaveDirectory()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Frame Rate")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("Frame Rate", selection: $selectedFPS) {
                    ForEach(FPSOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .frame(width: 170)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Scale")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("Scale", selection: $selectedScale) {
                    ForEach(ScaleOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .frame(width: 190)
            }

            Spacer()
        }
    }

    private var privacyAndFFmpegNote: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("All conversions are local. Barley uses ffmpeg by default for the most consistent output and falls back to native conversion when needed.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if ffmpegInstalled {
                Label("ffmpeg is installed and used by default.", systemImage: "checkmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(.green)
            } else {
                HStack(spacing: 8) {
                    Label("ffmpeg is not installed. Native conversion will be used.", systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.orange)

                    Button("Install ffmpeg") {
                        installFFmpeg()
                    }
                    .buttonStyle(.bordered)

                    Button("Homebrew Setup") {
                        openHomebrewWebsite()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 8) {
            Button("Convert to GIF") {
                convertVideo()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isConverting || selectedVideoURL == nil)

            if isConverting {
                Button("Cancel conversion") {
                    cancelConversion()
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
    }

    private var recentOutputs: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent GIFs")
                .font(.callout.weight(.medium))

            if recentOutputURLs.isEmpty {
                Text("No converted GIFs yet.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(recentOutputURLs, id: \.path) { url in
                    recentOutputRow(url: url)
                }
            }
        }
    }

    private func recentOutputRow(url: URL) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(url.lastPathComponent)
                    .font(.footnote.weight(.medium))
                Text(url.path)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button("Reveal in Finder") {
                revealInFinder(url: url)
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 6)
    }

    private func pickVideo() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.mpeg4Movie, .quickTimeMovie, .movie]

        if panel.runModal() == .OK {
            selectedVideoURL = panel.url
            statusMessage = nil
            errorMessage = nil
        }
    }

    private func pickSaveDirectory() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            saveDirectoryPath = url.path
        }
    }

    private func convertVideo() {
        guard let selectedVideoURL else {
            errorMessage = "Choose a MOV or MP4 video first."
            return
        }

        let saveURL = URL(fileURLWithPath: saveDirectoryPath)
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: saveURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            errorMessage = "Save location must be an existing folder."
            return
        }

        isConverting = true
        statusMessage = nil
        errorMessage = nil

        let settings = GIFConversionSettings(
            fps: selectedFPS.rawValue,
            maxDimension: selectedScale.rawValue
        )

        let task = Task {
            do {
                let result = try await VideoToGIFConverter.convert(
                    videoURL: selectedVideoURL,
                    saveDirectory: saveURL,
                    settings: settings
                )

                await MainActor.run {
                    isConverting = false
                    addRecentOutput(result.outputURL)
                    statusMessage = "Saved \(result.outputURL.lastPathComponent) using \(result.engineUsed.title)."
                    errorMessage = nil
                    ffmpegInstalled = VideoToGIFConverter.ffmpegExecutableURL() != nil
                    conversionTask = nil
                    resetAfterSuccessfulConversion()
                }
            } catch is CancellationError {
                await MainActor.run {
                    isConverting = false
                    statusMessage = "Conversion cancelled."
                    errorMessage = nil
                    ffmpegInstalled = VideoToGIFConverter.ffmpegExecutableURL() != nil
                    conversionTask = nil
                }
            } catch {
                await MainActor.run {
                    isConverting = false
                    statusMessage = nil
                    errorMessage = error.localizedDescription
                    ffmpegInstalled = VideoToGIFConverter.ffmpegExecutableURL() != nil
                    conversionTask = nil
                }
            }
        }
        conversionTask = task
    }

    private func cancelConversion() {
        guard isConverting else {
            return
        }
        statusMessage = "Cancelling conversion..."
        errorMessage = nil
        conversionTask?.cancel()
    }

    private func revealInFinder(url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            recentOutputURLs.removeAll { $0.path == url.path }
            persistRecentOutputs()
            errorMessage = "Converted GIF file was not found on disk."
            return
        }

        let parentPath = url.deletingLastPathComponent().path
        let didReveal = NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: parentPath)

        if !didReveal {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    private func installFFmpeg() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = [
            "-e", "tell application \"Terminal\" to activate",
            "-e", "tell application \"Terminal\" to do script \"brew install ffmpeg\""
        ]

        do {
            try process.run()
            statusMessage = "Opened Terminal to run: brew install ffmpeg"
            errorMessage = nil
        } catch {
            errorMessage = "Could not open Terminal for installation. You can run 'brew install ffmpeg' manually."
        }
    }

    private func openHomebrewWebsite() {
        guard let url = URL(string: "https://brew.sh") else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    private static func defaultSaveDirectoryPath() -> String {
        FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first?.path
            ?? FileManager.default.homeDirectoryForCurrentUser.path
    }

    private func resetAfterSuccessfulConversion() {
        selectedVideoURL = nil
        selectedFPS = .twelve
        selectedScale = .px1200
    }

    private func loadRecentOutputs() {
        let paths = UserDefaults.standard.stringArray(forKey: Self.recentOutputPathsKey) ?? []
        recentOutputURLs = paths.map(URL.init(fileURLWithPath:))
        pruneMissingRecentOutputs()
    }

    private func addRecentOutput(_ url: URL) {
        pruneMissingRecentOutputs()
        recentOutputURLs.removeAll { $0.path == url.path }
        recentOutputURLs.insert(url, at: 0)
        if recentOutputURLs.count > 20 {
            recentOutputURLs = Array(recentOutputURLs.prefix(20))
        }
        persistRecentOutputs()
    }

    private func pruneMissingRecentOutputs() {
        recentOutputURLs.removeAll { !FileManager.default.fileExists(atPath: $0.path) }
        persistRecentOutputs()
    }

    private func persistRecentOutputs() {
        UserDefaults.standard.set(recentOutputURLs.map(\.path), forKey: Self.recentOutputPathsKey)
    }
}

#Preview {
    VideoToGIFFeatureView()
}
