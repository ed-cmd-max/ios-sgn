import Foundation

struct PerfilDto: Decodable, Sendable {
    let id: Int
    let usuario: String
    let nombreTecnico: String?
    let correoTec: String?
    let telefono: String?
    let departamento: String?
    let empresaOrigen: String?
    let usuarioMba: String?
    let codigoUsuario: String?
    let anydeskId: String?
    let fotoUrl: String?
    let sucursalCliente: StoreDto?
}

struct FotoResponse: Decodable, Sendable {
    let ok: Bool
    let fotoUrl: String?
    let mensaje: String?
    let error: String?
}

struct PerfilResponse: Decodable, Sendable {
    let ok: Bool
    let perfil: PerfilDto?
    let error: String?
}

struct SolicitanteDto: Decodable, Identifiable, Sendable {
    let id: Int
    let usuario: String
    let nombre: String?
    let correo: String?
    let telefono: String?
    let departamento: String?
    let empresaOrigen: String?
    let anydeskId: String?
    let usuarioMba: String?
    let codigoUsuario: String?
    let activo: Int
    let fotoUrl: String?
    let sucursalClienteId: Int?
    let tienda: StoreDto?

    var nombreVisible: String {
        guard let nombre, !nombre.isEmpty else { return usuario }
        return nombre
    }
    var estaActivo: Bool { activo == 1 }
}

struct SolicitantesResponse: Decodable, Sendable {
    let ok: Bool
    let solicitantes: [SolicitanteDto]
    let total: Int
    let error: String?
}

struct SolicitanteResponse: Decodable, Sendable {
    let ok: Bool
    let mensaje: String?
    let solicitante: SolicitanteDto?
    let error: String?
}