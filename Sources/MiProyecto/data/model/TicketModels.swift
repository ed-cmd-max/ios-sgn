import Foundation

struct TicketDto: Decodable, Identifiable, Sendable {
    let id: Int
    let codigoTicket: String
    let tipoTicket: String
    let categoria: String
    let prioridad: String
    let estado: String
    let titulo: String
    let descripcion: String
    let tiendaNombre: String?
    let empresaOrigen: String?
    let contactoTelefono: String?
    let numeroTicketMba: String?
    let fechaEscaladoMba: String?
    let calificacion: Int?
    let comentarioCalificacion: String?
    let fechaApertura: String?
    let fechaResolucion: String?
    let solucion: String?
    let createdAt: String?
    let solicitante: UserDto?
    let asignadoA: UserDto?
    let sucursalCliente: StoreDto?
    let adjuntos: [AttachmentDto]?

    var displayCode: String { codigoTicket.isEmpty ? "TK-\(id)" : codigoTicket }

    private enum CodingKeys: String, CodingKey {
        case id, codigoTicket, tipoTicket, categoria, prioridad, estado, titulo, descripcion
        case tiendaNombre, empresaOrigen, contactoTelefono, numeroTicketMba, fechaEscaladoMba
        case calificacion, comentarioCalificacion, fechaApertura, fechaResolucion, solucion, createdAt
        case solicitante, asignadoA, sucursalCliente, adjuntos
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? values.decode(Int.self, forKey: .id)) ?? 0
        codigoTicket = (try? values.decode(String.self, forKey: .codigoTicket)) ?? ""
        tipoTicket = (try? values.decode(String.self, forKey: .tipoTicket)) ?? "sistemas"
        categoria = (try? values.decode(String.self, forKey: .categoria)) ?? "General"
        prioridad = (try? values.decode(String.self, forKey: .prioridad)) ?? "media"
        estado = (try? values.decode(String.self, forKey: .estado)) ?? "abierto"
        titulo = (try? values.decode(String.self, forKey: .titulo)) ?? ""
        descripcion = (try? values.decode(String.self, forKey: .descripcion)) ?? ""
        tiendaNombre = try? values.decode(String.self, forKey: .tiendaNombre)
        empresaOrigen = try? values.decode(String.self, forKey: .empresaOrigen)
        contactoTelefono = try? values.decode(String.self, forKey: .contactoTelefono)
        numeroTicketMba = try? values.decode(String.self, forKey: .numeroTicketMba)
        fechaEscaladoMba = try? values.decode(String.self, forKey: .fechaEscaladoMba)
        calificacion = try? values.decode(Int.self, forKey: .calificacion)
        comentarioCalificacion = try? values.decode(String.self, forKey: .comentarioCalificacion)
        fechaApertura = try? values.decode(String.self, forKey: .fechaApertura)
        fechaResolucion = try? values.decode(String.self, forKey: .fechaResolucion)
        solucion = try? values.decode(String.self, forKey: .solucion)
        createdAt = try? values.decode(String.self, forKey: .createdAt)
        solicitante = try? values.decode(UserDto.self, forKey: .solicitante)
        asignadoA = try? values.decode(UserDto.self, forKey: .asignadoA)
        sucursalCliente = try? values.decode(StoreDto.self, forKey: .sucursalCliente)
        adjuntos = (try? values.decode([AttachmentDto].self, forKey: .adjuntos)) ?? []
    }
}

struct TicketListResponse: Decodable, Sendable {
    let ok: Bool
    let tickets: [TicketDto]
    let currentPage: Int
    let lastPage: Int
    let total: Int
    let stats: StatsDto?
    let esTecnico: Bool
    let error: String?

    private enum CodingKeys: String, CodingKey { case ok, tickets, currentPage, lastPage, total, stats, esTecnico, error }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        ok = (try? values.decode(Bool.self, forKey: .ok)) ?? false
        tickets = (try? values.decode([TicketDto].self, forKey: .tickets)) ?? []
        currentPage = (try? values.decode(Int.self, forKey: .currentPage)) ?? 1
        lastPage = (try? values.decode(Int.self, forKey: .lastPage)) ?? 1
        total = (try? values.decode(Int.self, forKey: .total)) ?? 0
        stats = try? values.decode(StatsDto.self, forKey: .stats)
        esTecnico = (try? values.decode(Bool.self, forKey: .esTecnico)) ?? false
        error = try? values.decode(String.self, forKey: .error)
    }
}

struct StatsDto: Decodable, Sendable {
    let total: Int
    let abiertos: Int
    let enMba: Int
    let resueltos: Int
    let cerrados: Int
    let urgentes: Int
    let sinAsignar: Int
}

struct TicketDetailResponse: Decodable, Sendable {
    let ok: Bool
    let ticket: TicketDto?
    let mensajes: [MessageDto]?
    let pdfUrl: String?
    let esTecnico: Bool
    let error: String?
}

struct MessageDto: Decodable, Identifiable, Sendable {
    let id: Int
    let usuarioId: Int
    let autorNombre: String?
    let autorFoto: String?
    let mensaje: String?
    let esNotaInterna: Bool
    let cambioEstado: String?
    let hora: String?
    let fecha: String?
    let adjuntos: [AttachmentDto]
    let usuario: UserDto?
    let createdAt: String?
}

struct AttachmentDto: Decodable, Identifiable, Hashable, Sendable {
    let id: Int
    let nombreOriginal: String
    let url: String
    let esImagen: Bool
    let mensajeId: Int?

    private enum CodingKeys: String, CodingKey {
        case id, nombreOriginal, nombreArchivo, nombre, filename, url, rutaArchivo, path, ruta
        case esImagen, isImage, mensajeId
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? values.decode(Int.self, forKey: .id)) ?? 0
        nombreOriginal = (try? values.decode(String.self, forKey: .nombreOriginal))
            ?? (try? values.decode(String.self, forKey: .nombreArchivo))
            ?? (try? values.decode(String.self, forKey: .nombre))
            ?? (try? values.decode(String.self, forKey: .filename))
            ?? ""
        url = (try? values.decode(String.self, forKey: .url))
            ?? (try? values.decode(String.self, forKey: .rutaArchivo))
            ?? (try? values.decode(String.self, forKey: .path))
            ?? (try? values.decode(String.self, forKey: .ruta))
            ?? ""
        esImagen = (try? values.decode(Bool.self, forKey: .esImagen))
            ?? (try? values.decode(Bool.self, forKey: .isImage))
            ?? false
        mensajeId = try? values.decode(Int.self, forKey: .mensajeId)
    }
}

struct ChatSyncResponse: Decodable, Sendable {
    let ok: Bool
    let mensajes: [MessageDto]
    let error: String?
}

struct SendMessageResponse: Decodable, Sendable {
    let ok: Bool
    let mensaje: MessageDto?
    let error: String?
}

struct EnlaceAdjuntoResponse: Decodable, Sendable {
    let ok: Bool
    let url: String?
    let expiraEn: String?
    let error: String?
}

struct GenericApiResponse: Decodable, Sendable {
    let ok: Bool
    let mensaje: String?
    let error: String?
}

struct CatalogResponse: Decodable, Sendable {
    let ok: Bool
    let tiendas: [StoreDto]
    let tecnicosSistemas: [UserDto]
    let categoriasSistemas: [CategoryGroupDto]
    let categoriasSoporte: [String]
}

struct CategoryGroupDto: Decodable, Sendable, Identifiable {
    let grupo: String
    let categorias: [String]
    var id: String { grupo }
}

struct DocumentosResponse: Decodable, Sendable {
    let ok: Bool
    let imprimirUrl: String?
    let wordMbaUrl: String?
    let expiraEn: String?
    let error: String?
}

enum TicketFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case open = "abierto"
    case inProgress = "en_proceso"
    case waiting = "en_espera"
    case inMba = "en_mba"
    case resolved = "resuelto"
    case closed = "cerrado"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "Todos"
        case .open: "Abiertos"
        case .inProgress: "En proceso"
        case .waiting: "En espera"
        case .inMba: "En MBA"
        case .resolved: "Resueltos"
        case .closed: "Cerrados"
        }
    }
}