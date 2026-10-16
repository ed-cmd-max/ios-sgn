#if canImport(Combine)
import Combine
import Foundation

struct SGNNotification: Identifiable, Sendable {
    let id: UUID
    let title: String
    let message: String
    let type: String
    let date: Date

    init(title: String, message: String, type: String) {
        id = UUID()
        self.title = title
        self.message = message
        self.type = type
        date = Date()
    }
}

@MainActor
final class NotificacionesManager: ObservableObject {
    static let shared = NotificacionesManager()
    @Published private(set) var items: [SGNNotification] = []

    func add(title: String, message: String, type: String) {
        items.insert(SGNNotification(title: title, message: message, type: type), at: 0)
        if items.count > 100 { items.removeLast(items.count - 100) }
    }

    func clear() { items.removeAll() }
}
#endif