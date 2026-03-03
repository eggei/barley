import SwiftUI

struct JWTFeatureView: View {
    @EnvironmentObject private var viewModel: JWTWorkbenchViewModel
    @State private var selectedTab: InspectorTab = .claims

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("JWT Decoder")
                    .font(.title3.weight(.semibold))
                Text("Decode JWTs and search claims locally.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            tokenInput
            actions

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            if !viewModel.payloadJSON.isEmpty {
                inspector
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var tokenInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("JWT Token")
                .font(.callout.weight(.medium))

            TextEditor(text: $viewModel.token)
                .font(.system(.callout, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.quaternary)
                )
                .frame(minHeight: 120, maxHeight: 180)
        }
    }

    private var actions: some View {
        HStack {
            Button("Decode") {
                viewModel.decodeToken()
            }
            .keyboardShortcut(.return, modifiers: [])
            .buttonStyle(.borderedProminent)

            Button("Clear") {
                viewModel.clearAll()
            }
            .buttonStyle(.bordered)

            Spacer()
        }
    }

    private var inspector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Inspector", selection: $selectedTab) {
                ForEach(InspectorTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            switch selectedTab {
            case .claims:
                claimsView
            case .payload:
                jsonPanel(viewModel.payloadJSON)
            case .header:
                jsonPanel(viewModel.headerJSON)
            }
        }
    }

    private var claimsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Search claim keys or values", text: $viewModel.claimQuery)
                .textFieldStyle(.roundedBorder)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    if viewModel.filteredClaims.isEmpty {
                        Text("No matching claims.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 6)
                    } else {
                        ForEach(viewModel.filteredClaims) { claim in
                            ClaimRow(entry: claim)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 220, maxHeight: 260)
        }
    }

    private func jsonPanel(_ json: String) -> some View {
        ScrollView {
            Text(json)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
        }
        .frame(minHeight: 220, maxHeight: 260)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary)
        )
    }
}

private enum InspectorTab: String, CaseIterable, Identifiable {
    case claims = "Claims"
    case payload = "Payload"
    case header = "Header"

    var id: String {
        rawValue
    }
}

private struct ClaimRow: View {
    let entry: ClaimEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.path)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Text(entry.value)
                .font(.callout.monospaced())
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary.opacity(0.7))
        )
    }
}

#Preview {
    JWTFeatureView()
        .environmentObject(JWTWorkbenchViewModel())
}
