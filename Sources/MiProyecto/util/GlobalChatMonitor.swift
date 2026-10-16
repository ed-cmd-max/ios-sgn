#if canImport(Combine)
import Combine
import Foundation

@MainActor
final class GlobalChatMonitor: ObservableObject {
    static let shared = GlobalChatMonitor()
    @Published private(set) var unreadCount = 0
    private var monitorTask: Task<Void, Never>?
    private var knownNewsIds: Set<Int>?

    func start() {
        guard monitorTask == nil else { return }
        monitorTask = Task {
            while !Task.isCancelled {
                await refreshNews()
                guard !Task.isCancelled else { break }
                try? await Task.sleep(nanoseconds: 60_000_000_000)
            }
        }
    }

    func stop() {
        monitorTask?.cancel()
        monitorTask = nil
    }

    private func refreshNews() async {
        guard let response = try? await ApiService.shared.getNoticias(), response.ok else { return }
        let activeNews = response.noticias.filter(\.esIncidenciaActiva)
        let newsIds = Set(activeNews.map(\.id))
        if let knownNewsIds {
            for noticia in activeNews where !knownNewsIds.contains(noticia.id) {
                NotificacionesManager.shared.add(title: noticia.titulo, message: noticia.descripcion, type: "noticia")
                try? await NotificationHelper.show(title: noticia.titulo, message: noticia.descripcion)
            }
        }
        knownNewsIds = newsIds
        unreadCount = activeNews.count
    }
}
#endif