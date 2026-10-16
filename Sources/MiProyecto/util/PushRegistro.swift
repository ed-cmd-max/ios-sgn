import Foundation

enum PushRegistro {
    static func registrar(token: String) async throws {
        let response = try await ApiService.shared.registerPushToken(token)
        guard response.ok else { throw ApiRequestError.httpStatus(400, response.error) }
    }
}