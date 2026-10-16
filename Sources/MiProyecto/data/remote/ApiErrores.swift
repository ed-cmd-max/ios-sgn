import Foundation

enum LoginError: LocalizedError {
    case credentials(String?)
    case inactive(String?)
    case throttled(String?)
    case server(String?)
    case connection
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .credentials(let message):
            message ?? "Usuario o contraseña incorrectos. Revisa los datos e intenta de nuevo."
        case .inactive(let message):
            message ?? "Tu cuenta está inactiva. Contacta al administrador."
        case .throttled(let message):
            message ?? "Demasiados intentos. Espera un minuto antes de volver a intentar."
        case .server(let message):
            message ?? "El servidor no pudo procesar la solicitud. Intenta más tarde."
        case .connection:
            "No se pudo contactar al servidor. Revisa tu conexión a internet."
        case .invalidResponse:
            "El servidor devolvió una respuesta que no se pudo leer."
        }
    }
}

enum TicketsError: LocalizedError {
    case unauthorized
    case server(String?)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            "La sesión no está disponible. Inicia sesión nuevamente."
        case .server(let message):
            message ?? "No se pudieron cargar los tickets. Intenta otra vez."
        case .invalidResponse:
            "El servidor devolvió una respuesta que no se pudo leer."
        }
    }
}