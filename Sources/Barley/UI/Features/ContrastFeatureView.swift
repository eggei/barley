import AppKit
import SwiftUI

struct ContrastFeatureView: View {
    @State private var foregroundHex: String = "#FFFFFF"
    @State private var backgroundHex: String = "#1D1D1F"
    @State private var report: ContrastReport?
    @State private var errorMessage: String?
    @StateObject private var colorPanelBridge = ColorPanelBridge()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Color Contrast")
                    .font(.title3.weight(.semibold))
                Text("Check WCAG 2.1 contrast compliance between foreground and background HEX colors.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            colorInputs
            swatchPreview
            textPreview
            actions

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            if let report {
                contrastResultsTable(report: report)
            }

            Spacer(minLength: 0)
        }
        .onAppear {
            evaluateContrast()
        }
        .onChange(of: foregroundHex) { _ in
            evaluateContrast()
        }
        .onChange(of: backgroundHex) { _ in
            evaluateContrast()
        }
    }

    private var colorInputs: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Foreground HEX")
                    .font(.callout.weight(.medium))
                TextField("#FFFFFF", text: $foregroundHex)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.callout, design: .monospaced))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Background HEX")
                    .font(.callout.weight(.medium))
                TextField("#000000", text: $backgroundHex)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.callout, design: .monospaced))
            }
        }
    }

    private var swatchPreview: some View {
        let foreground = sanitizedHex(foregroundHex)
        let background = sanitizedHex(backgroundHex)

        return HStack(spacing: 10) {
            swatch(
                hex: foreground,
                label: "Foreground",
                selection: foregroundColorSelection
            )
            swatch(
                hex: background,
                label: "Background",
                selection: backgroundColorSelection
            )
            Spacer()
        }
    }

    private var actions: some View {
        HStack {
            Button("Swap") {
                let previousForeground = foregroundHex
                foregroundHex = backgroundHex
                backgroundHex = previousForeground
            }
            .buttonStyle(.bordered)

            Spacer()
        }
    }

    private var textPreview: some View {
        let foreground = Color(hex: foregroundHex) ?? .primary
        let background = Color(hex: backgroundHex) ?? .clear

        return VStack(alignment: .leading, spacing: 6) {
            Text("Text Preview")
                .font(.callout.weight(.medium))

            Text("Barley is awesome")
                .font(.title3.weight(.semibold))
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 16)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(background)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
        }
    }

    private func contrastResultsTable(report: ContrastReport) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WCAG 2.1 Results")
                .font(.headline)

            VStack(alignment: .leading, spacing: 2) {
                Text("Contrast ratio")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(report.ratioLabel)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
            }

            VStack(spacing: 0) {
                tableHeader

                ForEach(report.rows) { row in
                    Divider()
                    tableRow(row)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var tableHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("WCAG Rule")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Target")
                .frame(width: 170, alignment: .leading)
            Text("Status")
                .frame(width: 90, alignment: .leading)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.quaternary)
    }

    private func tableRow(_ row: ContrastResultRow) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(row.criterion)
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(row.target)
                .font(.callout)
                .frame(width: 170, alignment: .leading)

            HStack(spacing: 6) {
                Image(systemName: row.status == .pass ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(row.status == .pass ? .green : .red)
                Text(row.status.title)
                    .foregroundStyle(row.status == .pass ? .green : .red)
            }
            .font(.callout.weight(.medium))
            .frame(width: 90, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private func evaluateContrast() {
        do {
            report = try ContrastAnalyzer.buildReport(
                foregroundHex: foregroundHex,
                backgroundHex: backgroundHex
            )
            errorMessage = nil
        } catch let error as ColorHexError {
            report = nil
            errorMessage = error.errorDescription
        } catch {
            report = nil
            errorMessage = "Unable to calculate contrast results."
        }
    }

    private func sanitizedHex(_ input: String) -> String {
        input.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    private var foregroundColorSelection: Binding<Color> {
        Binding(
            get: { Color(hex: foregroundHex) ?? .white },
            set: { newColor in
                guard let hex = newColor.hexString else {
                    return
                }
                foregroundHex = hex
            }
        )
    }

    private var backgroundColorSelection: Binding<Color> {
        Binding(
            get: { Color(hex: backgroundHex) ?? .black },
            set: { newColor in
                guard let hex = newColor.hexString else {
                    return
                }
                backgroundHex = hex
            }
        )
    }

    @ViewBuilder
    private func swatch(hex: String, label: String, selection: Binding<Color>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Button {
                    openColorPanel(currentHex: hex, selection: selection)
                } label: {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(hex: hex) ?? .clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                        .frame(width: 30, height: 20)
                }
                .buttonStyle(.plain)
                .help("Click to choose \(label.lowercased()) color")

                Text(hex.isEmpty ? "--" : hex)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func openColorPanel(currentHex: String, selection: Binding<Color>) {
        let startingColor = Color(hex: currentHex) ?? selection.wrappedValue
        let startingNSColor = NSColor(startingColor).usingColorSpace(.sRGB) ?? .white

        colorPanelBridge.open(initialColor: startingNSColor) { changedNSColor in
            selection.wrappedValue = Color(nsColor: changedNSColor)
        }
    }
}

private extension Color {
    init?(hex: String) {
        var value = hex
        if value.hasPrefix("#") {
            value.removeFirst()
        }

        if value.count == 3 {
            value = value.map { "\($0)\($0)" }.joined()
        }

        guard value.count == 6,
              let intValue = UInt64(value, radix: 16)
        else {
            return nil
        }

        let red = Double((intValue & 0xFF0000) >> 16) / 255.0
        let green = Double((intValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(intValue & 0x0000FF) / 255.0

        self = Color(red: red, green: green, blue: blue)
    }

    var hexString: String? {
        guard let srgb = NSColor(self).usingColorSpace(.sRGB) else {
            return nil
        }

        let red = Int(round(srgb.redComponent * 255.0))
        let green = Int(round(srgb.greenComponent * 255.0))
        let blue = Int(round(srgb.blueComponent * 255.0))

        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}

@MainActor
private final class ColorPanelBridge: ObservableObject {
    private var onChange: ((NSColor) -> Void)?

    func open(initialColor: NSColor, onChange: @escaping (NSColor) -> Void) {
        self.onChange = onChange

        let panel = NSColorPanel.shared
        panel.color = initialColor
        panel.isContinuous = true
        panel.setTarget(self)
        panel.setAction(#selector(colorChanged(_:)))
        panel.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    @objc
    private func colorChanged(_ sender: NSColorPanel) {
        onChange?(sender.color)
    }
}

#Preview {
    ContrastFeatureView()
}
