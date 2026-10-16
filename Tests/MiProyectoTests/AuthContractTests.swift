import Foundation
import Testing
@testable import SGNTickets

@Test func loginRequestMatchesServerContract() throws {
    let data = try JSONEncoder().encode(LoginRequest(usuario: "tecnico", clave: "secreto"))
    let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: String])

    #expect(object["usuario"] == "tecnico")
    #expect(object["clave"] == "secreto")
    #expect(object["device_name"] == "iPhone")
}

@Test func userDecodesServerAliases() throws {
    let data = Data(#"{"id":7,"usuario":"tecnico","nombre_tecnico":"Ana Pérez","correo_tec":"ana@example.com"}"#.utf8)
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let user = try decoder.decode(UserDto.self, from: data)

    #expect(user.id == 7)
    #expect(user.nombre == "Ana Pérez")
    #expect(user.correo == "ana@example.com")
}

@Test func ticketResponseDecodesLaravelSnakeCase() throws {
    let data = Data(#"{"ok":true,"tickets":[{"id":12,"codigo_ticket":"TK-12","titulo":"Acceso","descripcion":"No puedo entrar","categoria":"Usuarios","prioridad":"alta","estado":"abierto","tienda_nombre":"Quito","fecha_apertura":"2026-10-15"}],"current_page":1,"last_page":2,"total":21}"#.utf8)
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let response = try decoder.decode(TicketListResponse.self, from: data)

    #expect(response.currentPage == 1)
    #expect(response.lastPage == 2)
    #expect(response.total == 21)
    #expect(response.tickets.first?.displayCode == "TK-12")
    #expect(response.tickets.first?.tiendaNombre == "Quito")
}

@Test func chatResponseDecodesPrivateAudioAttachment() throws {
    let data = Data(#"{"ok":true,"mensajes":[{"id":41,"usuario_id":7,"autor_nombre":"Ana Pérez","mensaje":"","es_nota_interna":false,"adjuntos":[{"id":22,"nombre_archivo":"nota.m4a","ruta_archivo":"/api/v1/tickets/adjuntos/22","is_image":false}]}],"error":null}"#.utf8)
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let response = try decoder.decode(ChatSyncResponse.self, from: data)
    let attachment = try #require(response.mensajes.first?.adjuntos.first)

    #expect(response.ok)
    #expect(response.mensajes.first?.usuarioId == 7)
    #expect(attachment.nombreOriginal == "nota.m4a")
    #expect(attachment.id == 22)
    #expect(!attachment.esImagen)
}

@Test func apiBaseURLRemainsUnchangedUntilLocalBackendTesting() {
    #expect(ApiClient.baseURL.absoluteString == "https://novitec.com.ec/sgn/")
}

