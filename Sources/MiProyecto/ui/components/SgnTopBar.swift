#if canImport(SwiftUI)
import SwiftUI

struct SgnTopBar: View {
    let title: String
    var subtitle: String?
    var leading: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            if let leading {
                Button(action: leading) { Image(systemName: "chevron.left") }
                    .accessibilityLabel("Volver")
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                if let subtitle { Text(subtitle).font(.caption).foregroundStyle(.secondary) }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}
#endif