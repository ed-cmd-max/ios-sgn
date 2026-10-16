#if canImport(SwiftUI)
import SwiftUI

struct SgnErrorBanner: View {
    let message: String
    var retry: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
            Text(message).font(.subheadline).frame(maxWidth: .infinity, alignment: .leading)
            if let retry { Button("Reintentar", action: retry).font(.caption.weight(.semibold)) }
        }
        .padding(12)
        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
}
#endif