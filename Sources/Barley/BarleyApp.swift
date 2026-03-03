import AppKit
import SwiftUI

@main
struct BarleyApp: App {
    @StateObject private var viewModel = JWTWorkbenchViewModel()
    @State private var selectedFeature: BarleyFeature = .jwt

    init() {
        NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        Window("Barley", id: BarleyWindow.main) {
            ContentView(selectedFeature: $selectedFeature)
                .environmentObject(viewModel)
        }
        .defaultSize(width: 860, height: 620)

        MenuBarExtra("Barley", systemImage: "key.horizontal") {
            MenuBarLauncherView(selectedFeature: $selectedFeature)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
        }
    }
}

private enum BarleyWindow {
    static let main = "barley-main-window"
}

private struct MenuBarLauncherView: View {
    @Binding var selectedFeature: BarleyFeature
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Open Barley") {
            openMainWindow()
        }

        Divider()

        ForEach(BarleyFeature.allCases) { feature in
            Button {
                selectedFeature = feature
                openMainWindow()
            } label: {
                Label(feature.title, systemImage: feature.icon)
            }
        }

        Divider()

        if #available(macOS 14.0, *) {
            SettingsLink {
                Text("Settings")
            }
        } else {
            Button("Settings") {
                openSettingsWindow()
            }
        }

        Button("Quit Barley") {
            NSApplication.shared.terminate(nil)
        }
    }

    private func openMainWindow() {
        openWindow(id: BarleyWindow.main)
        activateApp()
        DispatchQueue.main.async {
            bringMainWindowToFront()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            bringMainWindowToFront()
        }
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

    private func bringMainWindowToFront() {
        let candidate = NSApplication.shared.windows
            .first { window in
                window.title == "Barley" && window.canBecomeMain && window.canBecomeKey
            }

        activateApp()
        candidate?.orderFrontRegardless()
        candidate?.makeKeyAndOrderFront(nil)
    }

    private func activateApp() {
        NSRunningApplication.current.activate(options: [.activateIgnoringOtherApps, .activateAllWindows])
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
