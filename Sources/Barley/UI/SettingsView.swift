import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Barley")
                .font(.title2.weight(.semibold))

            Text("Native macOS menu bar JWT utilities. All decoding happens locally and offline.")
                .foregroundStyle(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Foundation Scope")
                    .font(.headline)
                Text("- Menu bar app shell")
                Text("- JWT decode")
                Text("- Claim search")
                Text("- Contrast checker")
                Text("- Video to GIF")
            }

            Spacer()
        }
        .padding(20)
        .frame(width: 420, height: 260)
    }
}

#Preview {
    SettingsView()
}
