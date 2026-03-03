import AppKit
import SwiftUI

struct ContentView: View {
    @Binding var selectedFeature: BarleyFeature

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            contentArea
        }
        .frame(minWidth: 860, minHeight: 620)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Barley")
                .font(.title3.weight(.semibold))

            Text("Offline native tools")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            ForEach(BarleyFeature.allCases) { feature in
                Button {
                    selectedFeature = feature
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: feature.icon)
                            .frame(width: 16)
                        Text(feature.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedFeature == feature ? Color.accentColor.opacity(0.16) : .clear)
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                if #available(macOS 14.0, *) {
                    SettingsLink {
                        Text("Settings")
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button("Settings") {
                        openSettingsWindow()
                    }
                    .buttonStyle(.bordered)
                }

                Button("Quit Barley") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(14)
        .frame(width: 220)
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }

    private var contentArea: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                switch selectedFeature {
                case .jwt:
                    JWTFeatureView()
                case .contrast:
                    ContrastFeatureView()
                case .videoToGIF:
                    VideoToGIFFeatureView()
                }

                Divider()

                Text("Offline only. Data stays on your Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func openSettingsWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)

        let didOpenSettings = NSApplication.shared.sendAction(
            Selector(("showSettingsWindow:")),
            to: nil,
            from: nil
        )

        if !didOpenSettings {
            _ = NSApplication.shared.sendAction(
                Selector(("showPreferencesWindow:")),
                to: nil,
                from: nil
            )
        }
    }
}

enum BarleyFeature: String, CaseIterable, Identifiable {
    case jwt
    case contrast
    case videoToGIF

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .jwt:
            return "JWT Decoder"
        case .contrast:
            return "Contrast Checker"
        case .videoToGIF:
            return "Video to GIF"
        }
    }

    var icon: String {
        switch self {
        case .jwt:
            return "key.horizontal"
        case .contrast:
            return "circle.lefthalf.filled"
        case .videoToGIF:
            return "film"
        }
    }
}

#Preview {
    ContentView(selectedFeature: .constant(.jwt))
        .environmentObject(JWTWorkbenchViewModel())
}
