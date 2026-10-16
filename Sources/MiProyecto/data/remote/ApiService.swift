import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct UploadFile: Sendable {
    let fieldName: String
    let fileName: String
    let mimeType: String
    let data: Data
}

private struct APIErrorPayload: Decodable {
    let mensaje: String?
    let error: String?
}

private struct RatingRequest: Encodable {
    let calificacion: Int
    let comentario: String
}

enum ApiRequestError: LocalizedError {
    case httpStatus(Int, String?)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .httpStatus(_, let message): message ?? "El servidor no pudo completar la solicitud."
        case .invalidResponse: "El servidor devolvió una respuesta que no se pudo leer."
        }
    }
}

actor ApiService {
    static let shared = ApiService()

    func login(usuario: String, clave: String) async throws -> AuthenticatedSession {
        let (data, httpResponse) = try await perform(
            path: "api/v1/auth/login",
            method: "POST",
            body: try JSONEncoder().encode(LoginRequest(usuario: usuario, clave: clave)),
            authenticated: false
        )
        let body = try? decoder().decode(LoginResponse.self, from: data)
        guard (200..<300).contains(httpResponse.statusCode),
              body?.ok == true,
              let token = body?.token,
              let user = body?.user else {
            let message = body?.error ?? body?.mensaje
            switch httpResponse.statusCode {
            case 401, 422: throw LoginError.credentials(message)
            case 403: throw LoginError.inactive(message)
            case 429: throw LoginError.throttled(message)
            case 500...599: throw LoginError.server(message)
            default: throw LoginError.credentials(message)
            }
        }
        try TokenStore.save(token)
        return AuthenticatedSession(token: token, user: user)
    }

    func me() async throws -> LoginResponse {
        try await request(LoginResponse.self, path: "api/v1/auth/me")
    }

    func logout() async throws -> GenericApiResponse {
        try await request(GenericApiResponse.self, path: "api/v1/auth/logout", method: "POST")
    }

    func registerPushToken(_ token: String) async throws -> GenericApiResponse {
        try await request(GenericApiResponse.self, path: "api/v1/auth/fcm-token", method: "POST", body: jsonData(["token": token]))
    }

    func getNoticias(desdeId: Int? = nil) async throws -> NoticiasResponse {
        let query = desdeId.map { [URLQueryItem(name: "desde_id", value: String($0))] } ?? []
        return try await request(NoticiasResponse.self, path: "api/v1/noticias", query: query)
    }

    func publicarNoticia(_ fields: [String: String]) async throws -> NoticiaRespuesta {
        try await request(NoticiaRespuesta.self, path: "api/v1/noticias", method: "POST", body: jsonData(fields))
    }

    func resolverNoticia(id: Int, fields: [String: String]) async throws -> NoticiaRespuesta {
        try await request(NoticiaRespuesta.self, path: "api/v1/noticias/\(id)/resolver", method: "POST", body: jsonData(fields))
    }

    func subirFotoPerfil(_ file: UploadFile) async throws -> FotoResponse {
        try await request(FotoResponse.self, path: "api/v1/perfil/foto", method: "POST", files: [file])
    }

    func quitarFotoPerfil() async throws -> FotoResponse {
        try await request(FotoResponse.self, path: "api/v1/perfil/foto", method: "DELETE")
    }

    func getCatalogo() async throws -> CatalogResponse {
        try await request(CatalogResponse.self, path: "api/v1/catalogo")
    }

    func getAuditoria(query: String? = nil, estado: String? = nil, page: Int = 1) async throws -> AuditoriaResponse {
        var items = [URLQueryItem(name: "page", value: String(page))]
        if let query, !query.isEmpty { items.append(URLQueryItem(name: "q", value: query)) }
        if let estado, !estado.isEmpty { items.append(URLQueryItem(name: "estado", value: estado)) }
        return try await request(AuditoriaResponse.self, path: "api/v1/auditoria", query: items)
    }

    func getSolicitantes(query: String? = nil) async throws -> SolicitantesResponse {
        let items = query.map { [URLQueryItem(name: "q", value: $0)] } ?? []
        return try await request(SolicitantesResponse.self, path: "api/v1/solicitantes", query: items)
    }

    func getTickets(
        filter: TicketFilter = .all,
        query: String = "",
        page: Int = 1,
        prioridad: String? = nil,
        sinAsignar: Bool? = nil,
        categoria: String? = nil
    ) async throws -> TicketListResponse {
        var items = [URLQueryItem(name: "page", value: String(page))]
        if filter != .all { items.append(URLQueryItem(name: "estado", value: filter.rawValue)) }
        if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            items.append(URLQueryItem(name: "q", value: query.trimmingCharacters(in: .whitespacesAndNewlines)))
        }
        if let prioridad { items.append(URLQueryItem(name: "prioridad", value: prioridad)) }
        if let sinAsignar { items.append(URLQueryItem(name: "sin_asignar", value: sinAsignar ? "1" : "0")) }
        if let categoria { items.append(URLQueryItem(name: "categoria", value: categoria)) }
        return try await request(TicketListResponse.self, path: "api/v1/tickets", query: items)
    }

    func getTicketDetail(id: Int) async throws -> TicketDetailResponse {
        try await request(TicketDetailResponse.self, path: "api/v1/tickets/\(id)")
    }

    func createTicket(fields: [String: String], files: [UploadFile] = []) async throws -> GenericApiResponse {
        try await request(GenericApiResponse.self, path: "api/v1/tickets", method: "POST", formFields: fields, files: files)
    }

    func sendChatMessage(ticketId: Int, message: String, isInternal: Bool = false, files: [UploadFile] = []) async throws -> SendMessageResponse {
        var fields = ["mensaje": message]
        if isInternal { fields["es_nota_interna"] = "1" }
        return try await request(SendMessageResponse.self, path: "api/v1/tickets/\(ticketId)/chat", method: "POST", formFields: fields, files: files)
    }

    func syncChat(ticketId: Int, lastId: Int) async throws -> ChatSyncResponse {
        try await request(ChatSyncResponse.self, path: "api/v1/tickets/\(ticketId)/chat/sync", query: [URLQueryItem(name: "last_id", value: String(lastId))])
    }

    func calificarTicket(id: Int, rating: Int, comment: String) async throws -> GenericApiResponse {
        try await request(GenericApiResponse.self, path: "api/v1/tickets/\(id)/calificar", method: "POST", body: jsonData(RatingRequest(calificacion: rating, comentario: comment)))
    }

    func reabrirTicket(id: Int, reason: String) async throws -> GenericApiResponse {
        try await request(GenericApiResponse.self, path: "api/v1/tickets/\(id)/reabrir", method: "POST", body: jsonData(["motivo": reason]))
    }

    func cambiarEstado(id: Int, fields: [String: String], evidence: UploadFile? = nil) async throws -> GenericApiResponse {
        try await request(GenericApiResponse.self, path: "api/v1/tickets/\(id)/cambiar-estado", method: "POST", formFields: fields, files: evidence.map { [$0] } ?? [])
    }

    func asignarTicket(id: Int, technicianId: Int) async throws -> GenericApiResponse {
        let fields = ["tecnico_id": technicianId, "asignado_a_id": technicianId]
        return try await request(GenericApiResponse.self, path: "api/v1/tickets/\(id)/asignar", method: "POST", body: jsonData(fields))
    }

    func getPerfil() async throws -> PerfilResponse {
        try await request(PerfilResponse.self, path: "api/v1/perfil")
    }

    func guardarPerfil(_ fields: [String: String?]) async throws -> GenericApiResponse {
        try await request(GenericApiResponse.self, path: "api/v1/perfil", method: "POST", body: jsonData(fields))
    }

    func crearSolicitante(_ fields: [String: String]) async throws -> SolicitanteResponse {
        try await request(SolicitanteResponse.self, path: "api/v1/solicitantes", method: "POST", body: jsonData(fields))
    }

    func actualizarSolicitante(id: Int, fields: [String: String]) async throws -> SolicitanteResponse {
        try await request(SolicitanteResponse.self, path: "api/v1/solicitantes/\(id)", method: "POST", body: jsonData(fields))
    }

    func getAuditoriaDetalle(id: Int) async throws -> AuditoriaDetalleResponse {
        try await request(AuditoriaDetalleResponse.self, path: "api/v1/auditoria/\(id)/detalle")
    }

    func enlaceAdjunto(id: Int) async throws -> EnlaceAdjuntoResponse {
        try await request(EnlaceAdjuntoResponse.self, path: "api/v1/tickets/adjuntos/\(id)/enlace")
    }

    func getDocumentos(ticketId: Int) async throws -> DocumentosResponse {
        try await request(DocumentosResponse.self, path: "api/v1/tickets/\(ticketId)/documentos")
    }

    private func request<Response: Decodable>(
        _ type: Response.Type,
        path: String,
        method: String = "GET",
        query: [URLQueryItem] = [],
        body: Data? = nil,
        formFields: [String: String] = [:],
        files: [UploadFile] = [],
        authenticated: Bool = true
    ) async throws -> Response {
        let (data, response) = try await perform(
            path: path,
            method: method,
            query: query,
            body: body,
            formFields: formFields,
            files: files,
            authenticated: authenticated
        )
        guard (200..<300).contains(response.statusCode) else {
            let payload = try? decoder().decode(APIErrorPayload.self, from: data)
            throw ApiRequestError.httpStatus(response.statusCode, payload?.error ?? payload?.mensaje)
        }
        do {
            return try decoder().decode(type, from: data)
        } catch {
            throw ApiRequestError.invalidResponse
        }
    }

    private func perform(
        path: String,
        method: String,
        query: [URLQueryItem] = [],
        body: Data? = nil,
        formFields: [String: String] = [:],
        files: [UploadFile] = [],
        authenticated: Bool = true
    ) async throws -> (Data, HTTPURLResponse) {
        let url = path.split(separator: "/").reduce(ApiClient.baseURL) { partial, component in
            partial.appendingPathComponent(String(component))
        }
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw ApiRequestError.invalidResponse
        }
        if !query.isEmpty { components.queryItems = query }
        guard let requestURL = components.url else { throw ApiRequestError.invalidResponse }

        var request = URLRequest(url: requestURL)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if authenticated, let token = TokenStore.load() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if !formFields.isEmpty || !files.isEmpty {
            let boundary = "SGN-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.httpBody = multipartBody(fields: formFields, files: files, boundary: boundary)
        } else if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw ApiRequestError.invalidResponse }
        return (data, httpResponse)
    }

    private func multipartBody(fields: [String: String], files: [UploadFile], boundary: String) -> Data {
        var data = Data()
        for (name, value) in fields {
            data.appendUTF8("--\(boundary)\r\n")
            data.appendUTF8("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
            data.appendUTF8("\(value)\r\n")
        }
        for file in files {
            data.appendUTF8("--\(boundary)\r\n")
            data.appendUTF8("Content-Disposition: form-data; name=\"\(file.fieldName)\"; filename=\"\(file.fileName)\"\r\n")
            data.appendUTF8("Content-Type: \(file.mimeType)\r\n\r\n")
            data.append(file.data)
            data.appendUTF8("\r\n")
        }
        data.appendUTF8("--\(boundary)--\r\n")
        return data
    }

    private func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    private func jsonData<Value: Encodable>(_ value: Value) throws -> Data {
        try JSONEncoder().encode(value)
    }
}

private extension Data {
    mutating func appendUTF8(_ string: String) {
        append(contentsOf: string.utf8)
    }
}