#if canImport(SwiftUI)
import SwiftUI

struct ImageViewerDialog: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFit().frame(maxWidth: .infinity, maxHeight: .infinity)
            } placeholder: {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(.black)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar", systemImage: "xmark", action: dismiss.callAsFunction)
                        .labelStyle(.iconOnly)
                }
            }
        }
    }
}
#endif