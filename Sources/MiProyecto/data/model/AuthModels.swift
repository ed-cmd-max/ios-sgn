import Foundation

struct LoginRequest: Encodable {
    let usuario: String
    let clave: String
    let device_name = "iPhone"
}

struct UserDto: Decodable, Identifiable, Sendable {
    let id: Int
    let usuario: String
    let nombre: String
    let correo: String?
    let telefono: String?
    let departamento: String?
    let empresaOrigen: String?
    let anydeskId: String?
    let usuarioMba: String?
    let codigoUsuario: String?
    let esTecnicoSistemas: Bool
    let esAdmin: Bool
    let fotoUrl: String?
    let esGeneradorTickets: Bool
    let puedeAtenderTickets: Bool
    let puedeVerAuditoria: Bool
    let puedeCrearNoticias: Bool
    let puedeAdministrarSolicitantes: Bool
    let tienda: StoreDto?

    private enum CodingKeys: String, CodingKey {
        case id, usuario, nombre, nombreTecnico, nombreCompleto, name, correo, correoTec, email
        case telefono, departamento, empresaOrigen, anydeskId, usuarioMba, codigoUsuario
        case esTecnicoSistemas, esAdmin, fotoUrl, esGeneradorTickets, puedeAtenderTickets
        case puedeVerAuditoria, puedeCrearNoticias, puedeAdministrarSolicitantes, tienda
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? values.decode(Int.self, forKey: .id)) ?? 0
        usuario = (try? values.decode(String.self, forKey: .usuario)) ?? ""
        nombre = (try? values.decode(String.self, forKey: .nombre))
            ?? (try? values.decode(String.self, forKey: .nombreTecnico))
            ?? (try? values.decode(String.self, forKey: .nombreCompleto))
            ?? (try? values.decode(String.self, forKey: .name))
            ?? "Usuario"
        correo = (try? values.decode(String.self, forKey: .correo))
            ?? (try? values.decode(String.self, forKey: .correoTec))
            ?? (try? values.decode(String.self, forKey: .email))
        telefono = try? values.decode(String.self, forKey: .telefono)
        departamento = try? values.decode(String.self, forKey: .departamento)
        empresaOrigen = try? values.decode(String.self, forKey: .empresaOrigen)
        anydeskId = try? values.decode(String.self, forKey: .anydeskId)
        usuarioMba = try? values.decode(String.self, forKey: .usuarioMba)
        codigoUsuario = try? values.decode(String.self, forKey: .codigoUsuario)
        esTecnicoSistemas = (try? values.decode(Bool.self, forKey: .esTecnicoSistemas)) ?? false
        esAdmin = (try? values.decode(Bool.self, forKey: .esAdmin)) ?? false
        fotoUrl = try? values.decode(String.self, forKey: .fotoUrl)
        esGeneradorTickets = (try? values.decode(Bool.self, forKey: .esGeneradorTickets)) ?? false
        puedeAtenderTickets = (try? values.decode(Bool.self, forKey: .puedeAtenderTickets)) ?? false
        puedeVerAuditoria = (try? values.decode(Bool.self, forKey: .puedeVerAuditoria)) ?? false
        puedeCrearNoticias = (try? values.decode(Bool.self, forKey: .puedeCrearNoticias)) ?? false
        puedeAdministrarSolicitantes = (try? values.decode(Bool.self, forKey: .puedeAdministrarSolicitantes)) ?? false
        tienda = try? values.decode(StoreDto.self, forKey: .tienda)
    }

    var nombreMostrable: String {
        let displayName = nombre.trimmingCharacters(in: .whitespacesAndNewlines)
        return displayName.isEmpty || displayName == "Usuario" ? (usuario.isEmpty ? "Usuario" : usuario) : displayName
    }

    var esSolicitanteTienda: Bool { tienda != nil }
    var esTecnicoReal: Bool { (esTecnicoSistemas || esAdmin) && !esSolicitanteTienda }
    var esAdminReal: Bool { esAdmin && !esSolicitanteTienda }
}

struct StoreDto: Decodable, Identifiable, Sendable {
    let id: Int
    let codigo: String
    let nombre: String
    let provincia: String?

    private enum CodingKeys: String, CodingKey { case id, codigo, nombre, provincia }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? values.decode(Int.self, forKey: .id)) ?? 0
        codigo = (try? values.decode(String.self, forKey: .codigo)) ?? ""
        nombre = (try? values.decode(String.self, forKey: .nombre)) ?? ""
        provincia = try? values.decode(String.self, forKey: .provincia)
    }
}

struct LoginResponse: Decodable {
    let ok: Bool
    let mensaje: String?
    let token: String?
    let user: UserDto?
    let error: String?
}

struct AuthenticatedSession: Sendable {
    let token: String
    let user: UserDto
}

typealias AuthUser = UserDto