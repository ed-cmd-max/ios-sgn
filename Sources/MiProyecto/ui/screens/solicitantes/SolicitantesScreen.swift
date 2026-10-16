#if canImport(SwiftUI)
import SwiftUI

struct SolicitantesScreen: View {
    let user: UserDto
    @Environment(\.dismiss) private var dismiss
    @State private var solicitantes: [SolicitanteDto] = []
    @State private var stores: [StoreDto] = []
    @State private var editing: SolicitanteDto?
    @State private var query = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && solicitantes.isEmpty { ProgressView("Cargando solicitantes…") }
                else if solicitantes.isEmpty {
                    ContentUnavailableView("Sin solicitantes", systemImage: "person.2")
                } else {
                    List(solicitantes) { person in
                        Button {
                            if user.puedeAdministrarSolicitantes { editing = person }
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text(person.nombreVisible).font(.headline)
                                    Spacer()
                                    Text(person.usuario).font(.caption.monospaced()).foregroundStyle(.secondary)
                                }
                                Text(person.correo ?? person.usuario).font(.subheadline).foregroundStyle(.secondary)
                                HStack {
                                    Text(person.tienda?.nombre ?? "Sin tienda")
                                    Spacer()
                                    Text(person.estaActivo ? "Activo" : "Inactivo")
                                }
                                .font(.caption).foregroundStyle(person.estaActivo ? .green : .secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                    .refreshable { await load() }
                }
            }
            .navigationTitle("Solicitantes")
            .searchable(text: $query, prompt: "Buscar por nombre")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cerrar") { dismiss() } }
                if user.puedeAdministrarSolicitantes {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Nuevo usuario", systemImage: "person.badge.plus") { editing = newSolicitante }
                            .labelStyle(.iconOnly)
                    }
                }
            }
            .sheet(item: $editing) { person in
                SolicitanteEditorScreen(solicitante: person, stores: stores) { id, fields in
                    do {
                        let result = id == 0
                            ? try await ApiService.shared.crearSolicitante(fields)
                            : try await ApiService.shared.actualizarSolicitante(id: id, fields: fields)
                        guard result.ok else { return result.error ?? "No se pudieron guardar los cambios." }
                        await load()
                        return nil
                    } catch { return error.localizedDescription }
                }
            }
            .task(id: query) {
                try? await Task.sleep(nanoseconds: 300_000_000)
                await load()
            }
            .overlay(alignment: .bottom) {
                if let errorMessage { Text(errorMessage).font(.footnote).foregroundStyle(.red).padding() }
            }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let peopleRequest = ApiService.shared.getSolicitantes(query: query)
            async let catalogRequest = ApiService.shared.getCatalogo()
            let peopleResponse = try await peopleRequest
            let catalogResponse = try await catalogRequest
            solicitantes = peopleResponse.solicitantes
            stores = catalogResponse.tiendas
        }
        catch { errorMessage = error.localizedDescription }
    }

    private var newSolicitante: SolicitanteDto {
        SolicitanteDto(
            id: 0, usuario: "", nombre: "", correo: nil, telefono: nil, departamento: nil,
            empresaOrigen: "NOVICOMPU", anydeskId: nil, usuarioMba: nil, codigoUsuario: nil,
            activo: 1, fotoUrl: nil, sucursalClienteId: nil, tienda: nil
        )
    }
}

private struct SolicitanteEditorScreen: View {
    let solicitante: SolicitanteDto
    let stores: [StoreDto]
    let onSave: (Int, [String: String]) async -> String?
    @Environment(\.dismiss) private var dismiss
    @State private var usuario: String
    @State private var nombre: String
    @State private var correo: String
    @State private var telefono: String
    @State private var departamento: String
    @State private var empresa: String
    @State private var usuarioMba: String
    @State private var codigoUsuario: String
    @State private var anydeskId: String
    @State private var password = ""
    @State private var storeId: Int?
    @State private var activo: Bool
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(solicitante: SolicitanteDto, stores: [StoreDto], onSave: @escaping (Int, [String: String]) async -> String?) {
        self.solicitante = solicitante
        self.stores = stores
        self.onSave = onSave
        _usuario = State(initialValue: solicitante.usuario)
        _nombre = State(initialValue: solicitante.nombre ?? "")
        _correo = State(initialValue: solicitante.correo ?? "")
        _telefono = State(initialValue: solicitante.telefono ?? "")
        _departamento = State(initialValue: solicitante.departamento ?? "")
        _empresa = State(initialValue: solicitante.empresaOrigen ?? "NOVICOMPU")
        _usuarioMba = State(initialValue: solicitante.usuarioMba ?? "")
        _codigoUsuario = State(initialValue: solicitante.codigoUsuario ?? "")
        _anydeskId = State(initialValue: solicitante.anydeskId ?? "")
        _storeId = State(initialValue: solicitante.sucursalClienteId ?? solicitante.tienda?.id)
        _activo = State(initialValue: solicitante.activo == 1)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Cuenta") {
                    if solicitante.id == 0 { TextField("Usuario", text: $usuario).textInputAutocapitalization(.never) }
                    TextField("Nombre completo", text: $nombre)
                    if solicitante.id == 0 {
                        SecureField("Contraseña (mínimo 4 caracteres)", text: $password)
                    } else {
                        SecureField("Cambiar contraseña (opcional)", text: $password)
                        Toggle("Cuenta activa", isOn: $activo)
                    }
                }
                Section("Datos de contacto") {
                    TextField("Correo", text: $correo).keyboardType(.emailAddress).textInputAutocapitalization(.never)
                    TextField("Teléfono", text: $telefono).keyboardType(.phonePad)
                    TextField("Departamento", text: $departamento)
                    TextField("Empresa", text: $empresa)
                    Picker("Tienda", selection: $storeId) {
                        Text("Selecciona tienda").tag(Int?.none)
                        ForEach(stores) { store in Text("\(store.codigo) · \(store.nombre)").tag(Int?.some(store.id)) }
                    }
                }
                Section("Información adicional") {
                    TextField("Usuario MBA", text: $usuarioMba)
                    TextField("Código de usuario", text: $codigoUsuario)
                    TextField("AnyDesk", text: $anydeskId)
                }
                if let errorMessage { Section { Text(errorMessage).foregroundStyle(.red) } }
            }
            .navigationTitle(solicitante.id == 0 ? "Nuevo usuario" : "Editar usuario")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { Task { await save() } }.disabled(isSaving)
                }
            }
        }
    }

    private func save() async {
        if solicitante.id == 0 && usuario.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Ingresa el nombre de usuario."; return
        }
        if solicitante.id == 0 && password.count < 4 || !password.isEmpty && password.count < 4 {
            errorMessage = "La contraseña debe tener al menos 4 caracteres."; return
        }
        guard !nombre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { errorMessage = "Ingresa el nombre completo."; return }
        guard let storeId else { errorMessage = "Selecciona la tienda del solicitante."; return }
        var fields = [
            "nombre_tecnico": nombre.trimmingCharacters(in: .whitespacesAndNewlines),
            "correo_tec": correo.trimmingCharacters(in: .whitespacesAndNewlines),
            "empresa_origen": empresa,
            "departamento": departamento,
            "sucursal_cliente_id": String(storeId),
            "telefono": telefono,
            "usuario_mba": usuarioMba,
            "codigo_usuario": codigoUsuario,
            "anydesk_id": anydeskId
        ]
        if solicitante.id == 0 { fields["usuario"] = usuario.trimmingCharacters(in: .whitespacesAndNewlines) }
        if !password.isEmpty { fields["clave"] = password }
        if solicitante.id != 0 { fields["activo"] = activo ? "1" : "0" }
        isSaving = true
        defer { isSaving = false }
        if let error = await onSave(solicitante.id, fields) { errorMessage = error }
        else { dismiss() }
    }
}
#endif