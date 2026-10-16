#if canImport(Combine)
import Combine
import Foundation

@MainActor
final class ChatViewModel: ObservableObject {
    @Published private(set) var messages: [MessageDto] = []
    @Published var text = ""
    @Published private(set) var isLoading = true
    @Published private(set) var isSending = false
    @Published private(set) var errorMessage: String?
    private var lastMessageId = 0

    func setError(_ message: String) { errorMessage = message }

    func load(ticketId: Int) async {
        do {
            let response = try await ApiService.shared.getTicketDetail(id: ticketId)
            guard response.ok else { errorMessage = response.error; return }
            messages = response.mensajes ?? []
            lastMessageId = messages.map(\.id).max() ?? 0
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    func poll(ticketId: Int) async {
        do {
            let response = try await ApiService.shared.syncChat(ticketId: ticketId, lastId: lastMessageId)
            guard response.ok, !response.mensajes.isEmpty else { return }
            messages = (messages + response.mensajes).uniqued(by: \.id)
            lastMessageId = messages.map(\.id).max() ?? lastMessageId
        } catch { }
    }

    func send(ticketId: Int, files: [UploadFile] = [], isInternal: Bool = false) async -> Bool {
        let draft = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (!draft.isEmpty || !files.isEmpty), !isSending else { return false }
        isSending = true
        errorMessage = nil
        do {
            let response = try await ApiService.shared.sendChatMessage(ticketId: ticketId, message: draft, isInternal: isInternal, files: files)
            guard response.ok else { throw ApiRequestError.httpStatus(400, response.error) }
            if let message = response.mensaje {
                messages = (messages + [message]).uniqued(by: \.id)
                lastMessageId = max(lastMessageId, message.id)
            }
            text = ""
            isSending = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isSending = false
            return false
        }
    }
}

private extension Array {
    func uniqued<Key: Hashable>(by keyPath: KeyPath<Element, Key>) -> [Element] {
        var seen = Set<Key>()
        return filter { seen.insert($0[keyPath: keyPath]).inserted }
    }
}
#endif