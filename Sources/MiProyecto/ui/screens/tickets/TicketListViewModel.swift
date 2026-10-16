#if canImport(Combine)
import Combine
import Foundation

@MainActor
final class TicketListViewModel: ObservableObject {
    let user: UserDto
    @Published private(set) var tickets: [TicketDto] = []
    @Published var filter: TicketFilter = .all
    @Published var query = ""
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var stats: StatsDto?
    @Published private(set) var total = 0
    @Published private(set) var serverSaysTechnician = false
    private var currentPage = 1
    private var lastPage = 1

    init(user: UserDto) { self.user = user }

    var isTechnician: Bool { serverSaysTechnician && user.esTecnicoReal }

    var filters: [TicketFilter] {
        isTechnician
            ? [.all, .open, .inProgress, .waiting, .inMba, .resolved, .closed]
            : [.all, .open, .inProgress, .resolved]
    }

    var visibleTickets: [TicketDto] {
        let scoped = isTechnician ? tickets : tickets.filter { ticket in
            let isMine = ticket.solicitante?.id == user.id || ticket.solicitante?.usuario.caseInsensitiveCompare(user.usuario) == .orderedSame
            let storeId = user.tienda?.id
            let storeName = user.tienda?.nombre ?? ""
            let isMyStore = (storeId != nil && ticket.sucursalCliente?.id == storeId)
                || (!storeName.isEmpty && ticket.tiendaNombre?.localizedCaseInsensitiveContains(storeName) == true)
            return isMine || isMyStore
        }
        guard !isTechnician else { return scoped }
        return scoped.filter { ticket in
            switch filter {
            case .inProgress:
                ["en_proceso", "en_mba", "en_espera"].contains(ticket.estado)
            case .resolved:
                ["resuelto", "cerrado", "cancelado"].contains(ticket.estado)
            default:
                true
            }
        }
    }

    var canLoadMore: Bool { currentPage < lastPage && !isLoadingMore && !isLoading }

    func loadTickets() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let serverFilter: TicketFilter = !isTechnician && [.inProgress, .resolved].contains(filter) ? .all : filter
            let response = try await ApiService.shared.getTickets(filter: serverFilter, query: query, page: 1)
            tickets = response.tickets
            stats = response.stats
            total = response.total
            serverSaysTechnician = response.esTecnico
            currentPage = response.currentPage
            lastPage = response.lastPage
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMore() async {
        guard canLoadMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let serverFilter: TicketFilter = !isTechnician && [.inProgress, .resolved].contains(filter) ? .all : filter
            let response = try await ApiService.shared.getTickets(filter: serverFilter, query: query, page: currentPage + 1)
            guard response.currentPage == currentPage + 1 else { return }
            tickets = (tickets + response.tickets).reduce(into: [TicketDto]()) { result, ticket in
                if !result.contains(where: { $0.id == ticket.id }) { result.append(ticket) }
            }
            currentPage = response.currentPage
            lastPage = response.lastPage
            total = response.total
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
#endif