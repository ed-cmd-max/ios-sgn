#if canImport(SwiftUI)
import SwiftUI

struct NoticiaFormulario: View {
    let opciones: OpcionesNoticia?
    let onPublish: ([String: String]) async -> Bool
    @Environment(\.dismiss) private var dismiss
    @State private var titulo = ""
    @State private var descripcion = ""
    @State private var tipo = ""
    @State private var severidad = ""
    @State private var isSending = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Incidencia") {
                    TextField("Título", text: $titulo)
                    Picker("Tipo", selection: $tipo) {
                        ForEach(opciones?.tipos ?? [], id: \.self) { Text($0).tag($0) }
                    }
                    Picker("Severidad", selection: $severidad) {
                        ForEach(opciones?.severidades ?? [], id: \.self) { Text($0).tag($0) }
                    }
                    TextField("Descripción", text: $descripcion, axis: .vertical).lineLimit(4...8)
                }
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            }
            .navigationTitle("Nueva noticia")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Publicar") {
                        Task {
                            isSending = true
                            let success = await onPublish(["titulo": titulo, "descripcion": descripcion, "tipo_incidencia": tipo, "severidad": severidad])
                            isSending = false
                            if success { dismiss() }
                            else { errorMessage = "No se pudo publicar. Revisa los datos e intenta de nuevo." }
                        }
                    }
                    .disabled(isSending || titulo.isEmpty || descripcion.isEmpty)
                }
            }
        }
    }
}
#endif