import Foundation

struct NoticiaDto: Decodable, Identifiable, Sendable {
    let id: Int
    let tipoIncidencia: String
    let severidad: String
    let estado: String
    let titulo: String
    let descripcion: String
    let ultimaActualizacion: String?
    let fechaHora: String
    let fechaHoraActualizacion: String?
    let esIncidenciaActiva: Bool
    let autor: String
}

struct OpcionesNoticia: Decodable, Sendable {
    let tipos: [String]
    let severidades: [String]
    let estados: [String]
}

struct NoticiasResponse: Decodable, Sendable {
    let ok: Bool
    let noticias: [NoticiaDto]
    let puedeCrear: Bool
    let opciones: OpcionesNoticia?
    let error: String?
}

struct NoticiaRespuesta: Decodable, Sendable {
    let ok: Bool
    let mensaje: String?
    let noticia: NoticiaDto?
    let error: String?
}