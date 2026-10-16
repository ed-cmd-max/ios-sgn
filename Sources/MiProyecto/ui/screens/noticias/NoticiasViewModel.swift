#if canImport(Combine)
import Combine
import Foundation

@MainActor
final class NoticiasViewModel: ObservableObject {
    @Published private(set) var noticias: [NoticiaDto] = []
    @Published private(set) var puedeCrear = false
    @Published private(set) var opciones: OpcionesNoticia?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await ApiService.shared.getNoticias()
            guard response.ok else { errorMessage = response.error; return }
            noticias = response.noticias
            puedeCrear = response.puedeCrear
            opciones = response.opciones
        } catch { errorMessage = error.localizedDescription }
    }

    func publish(_ fields: [String: String]) async -> Bool {
        do {
            let response = try await ApiService.shared.publicarNoticia(fields)
            guard response.ok else { errorMessage = response.error ?? "No se pudo publicar la noticia."; return false }
            await load()
            return true
        } catch { errorMessage = error.localizedDescription; return false }
    }

    func resolve(_ noticia: NoticiaDto) async {
        do {
            let response = try await ApiService.shared.resolverNoticia(id: noticia.id, fields: ["estado": "resuelto"])
            guard response.ok else { errorMessage = response.error; return }
            await load()
        } catch { errorMessage = error.localizedDescription }
    }
}
#endif