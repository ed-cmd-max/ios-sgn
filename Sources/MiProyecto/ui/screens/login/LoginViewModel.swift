#if canImport(Combine)
import Combine
import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var usuario = ""
    @Published var clave = ""
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var session: AuthenticatedSession?

    init() {
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")
        if !isUITesting && TokenStore.load() != nil {
            Task { await restoreSession() }
        }
    }

    func login() async {
        let username = usuario.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !username.isEmpty, !clave.isEmpty else {
            errorMessage = "Ingresa tu usuario y contraseña."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            session = try await ApiService.shared.login(usuario: username, clave: clave)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logout() async {
        _ = try? await ApiService.shared.logout()
        TokenStore.delete()
        session = nil
        clave = ""
    }

    func loginWithBiometrics() async {
        guard TokenStore.load() != nil else {
            errorMessage = "Inicia sesión con tu usuario y contraseña primero."
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            guard try await BiometriaSegura.autenticar() else {
                errorMessage = "La autenticación biométrica no está disponible."
                return
            }
            await restoreSession()
        } catch {
            errorMessage = "No se pudo validar tu identidad."
        }
    }

    private func restoreSession() async {
        guard let token = TokenStore.load() else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await ApiService.shared.me()
            guard response.ok, let user = response.user else {
                TokenStore.delete()
                return
            }
            session = AuthenticatedSession(token: token, user: user)
        } catch {
            if let requestError = error as? ApiRequestError,
               case .httpStatus(401, _) = requestError {
                TokenStore.delete()
                errorMessage = "Tu sesión expiró. Inicia sesión nuevamente."
            } else {
                errorMessage = "No se pudo recuperar la sesión. Revisa tu conexión."
            }
        }
    }
}
#endif