#if canImport(SwiftUI)
import SwiftUI

struct LoginScreen: View {
    @StateObject private var viewModel = LoginViewModel()
    @AppStorage("biometria_activa") private var biometricEnabled = false

    var body: some View {
        Group {
            if let session = viewModel.session {
                MainContainerScreen(user: session.user) {
                    Task { await viewModel.logout() }
                }
            } else {
                loginForm
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.08))
    }

    private var loginForm: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("SGN Tickets")
                    .font(.largeTitle.weight(.bold))
                Text("Ingresa a tu cuenta")
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 14) {
                TextField("Usuario o correo", text: $viewModel.usuario)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                SecureField("Contraseña", text: $viewModel.clave)
                    .textContentType(.password)
                    .textFieldStyle(.roundedBorder)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }

            Button {
                Task { await viewModel.login() }
            } label: {
                HStack {
                    if viewModel.isLoading { ProgressView().tint(.white) }
                    Text(viewModel.isLoading ? "Ingresando…" : "Iniciar sesión")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.usuario.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.clave.isEmpty || viewModel.isLoading)

            if biometricEnabled && TokenStore.load() != nil {
                Button {
                    Task { await viewModel.loginWithBiometrics() }
                } label: {
                    Label("Ingresar con Face ID o Touch ID", systemImage: "faceid")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isLoading)
            }

        }
        .padding(28)
        .frame(maxWidth: 440)
    }
}
#endif