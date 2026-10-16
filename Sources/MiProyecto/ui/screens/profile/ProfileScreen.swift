#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import UIKit

struct ProfileScreen: View {
    let user: UserDto
    let onLogout: () -> Void
    let onOpenAudit: () -> Void
    let onOpenSolicitantes: () -> Void
    @StateObject private var viewModel = ProfileViewModel()
    @AppStorage("sgn_dark_theme") private var darkMode = false
    @AppStorage("biometria_activa") private var biometricEnabled = false
    @State private var showingPhotoPicker = false
    @State private var showingRemovePhoto = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        AvatarUsuario(nombre: user.nombreMostrable, fotoURL: FotoPerfil.urlSegura(viewModel.profile?.fotoUrl ?? user.fotoUrl), size: 58)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.nombreMostrable).font(.title3.weight(.semibold))
                            Text(user.usuario).font(.subheadline).foregroundStyle(.secondary)
                            Text(roleLabel).font(.caption.weight(.medium)).foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, 8)
                    Button {
                        showingPhotoPicker = true
                    } label: {
                        Label("Cambiar foto de perfil", systemImage: "camera")
                    }
                    if viewModel.profile?.fotoUrl != nil || user.fotoUrl != nil {
                        Button("Quitar foto", systemImage: "trash", role: .destructive) { showingRemovePhoto = true }
                    }
                }

                Section("Información") {
                    editableField("Correo", value: $viewModel.correo, contentType: .emailAddress)
                    editableField("Teléfono", value: $viewModel.telefono, contentType: .telephoneNumber)
                    editableField("Departamento", value: $viewModel.departamento)
                    editableField("Usuario MBA", value: $viewModel.usuarioMba)
                    editableField("Código de usuario", value: $viewModel.codigoUsuario)
                    editableField("AnyDesk", value: $viewModel.anydeskId)
                    LabeledContent("Tienda", value: viewModel.profile?.sucursalCliente?.nombre ?? user.tienda?.nombre ?? "No asignada")
                }

                Section("Preferencias") {
                    Toggle("Modo oscuro", isOn: $darkMode)
                    Toggle("Ingreso biométrico", isOn: $biometricEnabled)
                        .disabled(!BiometriaSegura.isAvailable || TokenStore.load() == nil)
                    NavigationLink { NotificationsScreen() } label: {
                        Label("Notificaciones", systemImage: "bell")
                    }
                }

                Section("Administración") {
                    if user.puedeVerAuditoria { Button("Auditoría", systemImage: "chart.bar.xaxis", action: onOpenAudit) }
                    if user.puedeAdministrarSolicitantes { Button("Solicitantes", systemImage: "person.2", action: onOpenSolicitantes) }
                }

                if viewModel.isEditing {
                    Section {
                        Button("Guardar cambios") { Task { await viewModel.save() } }
                            .disabled(viewModel.isSaving)
                        Button("Cancelar", role: .cancel) { Task { await viewModel.cancelEditing() } }
                    }
                } else {
                    Section { Button("Editar perfil", systemImage: "pencil") { viewModel.isEditing = true } }
                }

                Section { Button("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive, action: onLogout) }
                if let error = viewModel.errorMessage { Section { Text(error).foregroundStyle(.red) } }
                if let message = viewModel.feedbackMessage { Section { Text(message).foregroundStyle(.green) } }
            }
            .navigationTitle("Perfil")
            .overlay { if viewModel.isLoading { ProgressView() } }
            .refreshable { await viewModel.load() }
            .task { await viewModel.load() }
            .sheet(isPresented: $showingPhotoPicker) {
                ImagePicker { data in
                    guard let data else { return }
                    Task { await viewModel.uploadPhoto(data) }
                }
                .ignoresSafeArea()
            }
            .confirmationDialog("Quitar foto de perfil", isPresented: $showingRemovePhoto, titleVisibility: .visible) {
                Button("Quitar foto", role: .destructive) { Task { await viewModel.removePhoto() } }
            }
        }
    }

    private var roleLabel: String {
        if user.esGeneradorTickets { return "Generador de tickets" }
        if user.puedeAtenderTickets { return "Especialista de Sistemas TI" }
        if user.esAdmin { return "Administrador del SGN" }
        return "Usuario del SGN"
    }

    @ViewBuilder
    private func editableField(_ title: String, value: Binding<String>, contentType: UITextContentType? = nil) -> some View {
        if viewModel.isEditing {
            TextField(title, text: value)
                .textContentType(contentType)
                .textInputAutocapitalization(title == "Correo" ? .never : .sentences)
        } else {
            LabeledContent(title, value: value.wrappedValue.isEmpty ? "No disponible" : value.wrappedValue)
        }
    }
}

private struct ImagePicker: UIViewControllerRepresentable {
    let onImageSelected: (Data?) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(onImageSelected: onImageSelected, dismiss: dismiss)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ picker: UIImagePickerController, context: Context) { }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImageSelected: (Data?) -> Void
        let dismiss: DismissAction

        init(onImageSelected: @escaping (Data?) -> Void, dismiss: DismissAction) {
            self.onImageSelected = onImageSelected
            self.dismiss = dismiss
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let data = (info[.originalImage] as? UIImage)?.jpegData(compressionQuality: 0.9)
            onImageSelected(data)
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onImageSelected(nil)
            dismiss()
        }
    }
}
#endif