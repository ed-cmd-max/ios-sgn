#if canImport(SwiftUI)
import SwiftUI

struct NotificacionesModalSheet: View {
    @ObservedObject var manager = NotificacionesManager.shared

    var body: some View {
        NavigationStack {
            NotificationsScreen()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Limpiar", systemImage: "trash", role: .destructive) { manager.clear() }
                            .labelStyle(.iconOnly)
                    }
                }
        }
    }
}
#endif