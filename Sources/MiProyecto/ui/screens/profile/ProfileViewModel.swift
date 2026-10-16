#if canImport(Combine)
import Combine
import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var profile: PerfilDto?
    @Published var correo = ""
    @Published var telefono = ""
    @Published var departamento = ""
    @Published var usuarioMba = ""
    @Published var codigoUsuario = ""
    @Published var anydeskId = ""
    @Published var isEditing = false
    @Published private(set) var isSaving = false
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var feedbackMessage: String?

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await ApiService.shared.getPerfil()
            guard response.ok else { errorMessage = response.error; return }
            profile = response.perfil
            correo = response.perfil?.correoTec ?? ""
            telefono = response.perfil?.telefono ?? ""
            departamento = response.perfil?.departamento ?? ""
            usuarioMba = response.perfil?.usuarioMba ?? ""
            codigoUsuario = response.perfil?.codigoUsuario ?? ""
            anydeskId = response.perfil?.anydeskId ?? ""
        } catch { errorMessage = error.localizedDescription }
    }

    func save() async {
        if !correo.isEmpty && !correo.contains("@") {
            errorMessage = "El correo no tiene un formato válido."
            return
        }
        isSaving = true
        defer { isSaving = false }
        do {
            let response = try await ApiService.shared.guardarPerfil([
                "correo_tec": correo.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                "telefono": telefono.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                "departamento": departamento.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                "usuario_mba": usuarioMba.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                "codigo_usuario": codigoUsuario.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                "anydesk_id": anydeskId.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ])
            guard response.ok else { errorMessage = response.error ?? "No se pudieron guardar los datos."; return }
            isEditing = false
            feedbackMessage = response.mensaje ?? "Datos actualizados correctamente."
            await load()
        } catch { errorMessage = error.localizedDescription }
    }

    func cancelEditing() async {
        isEditing = false
        await load()
    }

    func uploadPhoto(_ data: Data) async {
        do {
            #if canImport(UIKit)
            guard let jpeg = FotoPerfil.prepararJPEG(data) else {
                errorMessage = "No se pudo leer la imagen elegida."
                return
            }
            #else
            let jpeg = data
            #endif
            let result = try await ApiService.shared.subirFotoPerfil(UploadFile(fieldName: "foto", fileName: "perfil.jpg", mimeType: "image/jpeg", data: jpeg))
            guard result.ok else { errorMessage = result.error ?? "No se pudo subir la foto."; return }
            feedbackMessage = result.mensaje ?? "Foto de perfil actualizada."
            await load()
        } catch { errorMessage = error.localizedDescription }
    }

    func removePhoto() async {
        do {
            let result = try await ApiService.shared.quitarFotoPerfil()
            guard result.ok else { errorMessage = result.error ?? "No se pudo quitar la foto."; return }
            feedbackMessage = result.mensaje ?? "Foto de perfil eliminada."
            await load()
        } catch { errorMessage = error.localizedDescription }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
#endif