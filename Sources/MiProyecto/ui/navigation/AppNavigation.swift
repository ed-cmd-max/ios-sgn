import Foundation

enum Screen: Hashable {
    case login
    case ticketList
    case ticketDetail(Int)
    case createTicket
    case auditoria
    case solicitantes
    case chat(Int, String)
}