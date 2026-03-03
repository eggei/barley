import Foundation
import Testing
@testable import Barley

struct VideoToGIFConverterTests {
    @Test
    func suggestedOutputURLAvoidsCollisions() throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let videoURL = root.appendingPathComponent("demo.mp4")
        FileManager.default.createFile(atPath: videoURL.path, contents: Data())

        let first = VideoToGIFConverter.suggestedOutputURL(for: videoURL, in: root)
        #expect(first.lastPathComponent == "demo.gif")

        FileManager.default.createFile(atPath: first.path, contents: Data())
        let second = VideoToGIFConverter.suggestedOutputURL(for: videoURL, in: root)
        #expect(second.lastPathComponent == "demo-1.gif")
    }
}
