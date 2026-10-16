#if canImport(SwiftUI)
import SwiftUI

struct NotificationsScreen: View {
    @ObservedObject private var manager = NotificacionesManager.shared

    var body: some View {
        Group {
            if manager.items.isEmpty {
                ContentUnavailableView("Sin notificaciones", systemImage: "bell")
            } else {
                List(manager.items) { item in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Label(item.title, systemImage: item.type == "chat" ? "bubble.left" : "newspaper")
                                .font(.headline)
                            Spacer()
                            Text(item.date, style: .relative).font(.caption).foregroundStyle(.secondary)
                        }
                        Text(item.message).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Notificaciones")
    }
}
#endif