import Foundation

struct AuditoriaResponse: Decodable, Sendable {
    let ok: Bool
    let kpis: KpiDataDto?
    let topTiendas: [TopTiendaDto]
    let especialistas: [EspecialistaDto]
    let tickets: [AuditoriaTicketDto]
    let currentPage: Int
    let lastPage: Int
    let totalListado: Int
    let error: String?
}

struct AuditoriaTicketDto: Decodable, Identifiable, Sendable {
    let id: Int
    let codigoTicket: String
    let titulo: String?
    let estado: String?
    let categoria: String?
    let prioridad: String?
    let tiendaNombre: String?
    let empresaOrigen: String?
    let calificacion: Int?
    let fechaApertura: String?
    let solicitanteNombre: String?
    let asignadoNombre: String?
}

struct KpiDataDto: Decodable, Sendable {
    let totalTickets: Int
    let resueltos: Int
    let abiertos: Int
    let enMba: Int
    let tasaResolucion: Float
}

struct TopTiendaDto: Decodable, Identifiable, Sendable {
    let tiendaNombre: String
    let total: Int
    var id: String { tiendaNombre }
}

struct EspecialistaDto: Decodable, Identifiable, Sendable {
    let id: Int
    let nombre: String
    let asignados: Int
    let resueltos: Int
    let calificacionPromedio: Float
}

struct AuditoriaDetalleResponse: Decodable, Sendable {
    let ok: Bool
    let ticket: TicketDto?
    let solicitanteNombre: String?
    let asignadoNombre: String?
    let tiendaNombre: String?
    let solucionTexto: String?
    let error: String?
}