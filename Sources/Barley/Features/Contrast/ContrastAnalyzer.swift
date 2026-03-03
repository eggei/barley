import AppKit
import Foundation

enum ContrastStatus: Equatable {
    case pass
    case fail

    var title: String {
        switch self {
        case .pass:
            return "Pass"
        case .fail:
            return "Fail"
        }
    }
}

struct ContrastResultRow: Identifiable, Equatable {
    let criterion: String
    let target: String
    let threshold: Double
    let status: ContrastStatus

    var id: String {
        "\(criterion)-\(target)-\(threshold)"
    }
}

struct ContrastReport: Equatable {
    let ratio: Double
    let rows: [ContrastResultRow]

    var ratioLabel: String {
        String(format: "%.2f:1", ratio)
    }
}

enum ColorHexError: LocalizedError, Equatable {
    case empty
    case invalidFormat

    var errorDescription: String? {
        switch self {
        case .empty:
            return "Enter both foreground and background HEX values."
        case .invalidFormat:
            return "Use 3-digit or 6-digit HEX (for example: #1A1A1A or #FA3)."
        }
    }
}

enum ContrastAnalyzer {
    static func buildReport(foregroundHex: String, backgroundHex: String) throws -> ContrastReport {
        let foreground = try color(fromHex: foregroundHex)
        let background = try color(fromHex: backgroundHex)
        let ratio = contrastRatio(foreground: foreground, background: background)

        return ContrastReport(
            ratio: ratio,
            rows: [
                ContrastResultRow(
                    criterion: "1.4.3 Contrast (Minimum) (AA)",
                    target: "Regular text",
                    threshold: 4.5,
                    status: ratio >= 4.5 ? .pass : .fail
                ),
                ContrastResultRow(
                    criterion: "1.4.3 Contrast (Minimum) (AA)",
                    target: "Large text",
                    threshold: 3.0,
                    status: ratio >= 3.0 ? .pass : .fail
                ),
                ContrastResultRow(
                    criterion: "1.4.6 Contrast (Enhanced) (AAA)",
                    target: "Regular text",
                    threshold: 7.0,
                    status: ratio >= 7.0 ? .pass : .fail
                ),
                ContrastResultRow(
                    criterion: "1.4.6 Contrast (Enhanced) (AAA)",
                    target: "Large text",
                    threshold: 4.5,
                    status: ratio >= 4.5 ? .pass : .fail
                ),
                ContrastResultRow(
                    criterion: "1.4.11 Non-text Contrast (AA)",
                    target: "UI components and graphical objects",
                    threshold: 3.0,
                    status: ratio >= 3.0 ? .pass : .fail
                )
            ]
        )
    }

    private static func color(fromHex rawHex: String) throws -> NSColor {
        let trimmed = rawHex.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ColorHexError.empty
        }

        var hex = trimmed
        if hex.hasPrefix("#") {
            hex.removeFirst()
        }

        if hex.count == 3 {
            hex = hex.map { "\($0)\($0)" }.joined()
        }

        guard hex.count == 6,
              let value = UInt64(hex, radix: 16)
        else {
            throw ColorHexError.invalidFormat
        }

        let red = CGFloat((value & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((value & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(value & 0x0000FF) / 255.0

        return NSColor(srgbRed: red, green: green, blue: blue, alpha: 1.0)
    }

    private static func contrastRatio(foreground: NSColor, background: NSColor) -> Double {
        let fgLuminance = relativeLuminance(for: foreground)
        let bgLuminance = relativeLuminance(for: background)

        let lighter = max(fgLuminance, bgLuminance)
        let darker = min(fgLuminance, bgLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private static func relativeLuminance(for color: NSColor) -> Double {
        let srgb = color.usingColorSpace(.sRGB) ?? color

        func adjust(_ value: CGFloat) -> Double {
            let channel = Double(value)
            if channel <= 0.03928 {
                return channel / 12.92
            }
            return pow((channel + 0.055) / 1.055, 2.4)
        }

        let r = adjust(srgb.redComponent)
        let g = adjust(srgb.greenComponent)
        let b = adjust(srgb.blueComponent)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }
}
