import Testing
@testable import Barley

struct ContrastAnalyzerTests {
    @Test
    func blackOnWhitePassesAllChecks() throws {
        let report = try ContrastAnalyzer.buildReport(
            foregroundHex: "#000000",
            backgroundHex: "#FFFFFF"
        )

        #expect(report.ratio > 20.9)
        #expect(report.rows.allSatisfy { $0.status == .pass })
    }

    @Test
    func sameColorsFailAllChecks() throws {
        let report = try ContrastAnalyzer.buildReport(
            foregroundHex: "#777777",
            backgroundHex: "#777777"
        )

        #expect(report.ratio == 1.0)
        #expect(report.rows.allSatisfy { $0.status == .fail })
    }

    @Test
    func supportsShortHexFormat() throws {
        let report = try ContrastAnalyzer.buildReport(
            foregroundHex: "#FFF",
            backgroundHex: "#000"
        )

        #expect(report.rows.allSatisfy { $0.status == .pass })
    }

    @Test
    func rejectsInvalidHexFormat() {
        #expect(throws: ColorHexError.invalidFormat) {
            _ = try ContrastAnalyzer.buildReport(
                foregroundHex: "#ZXY123",
                backgroundHex: "#000000"
            )
        }
    }
}
