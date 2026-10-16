#if canImport(Combine)
import Combine
import Foundation

enum FormularioTicket: Equatable {
    case casoMBA3
    case datosEspecificos
    case descripcionEstandar
}

enum VarianteEspecifica: Equatable {
    case crearVendedor
    case crearUsuarioMBA
    case iconoMilenium
    case iconoMBA

    var tituloCaso: String {
        switch self {
        case .crearVendedor: "DATOS PARA CREAR UN VENDEDOR"
        case .crearUsuarioMBA: "DATOS PARA CREAR UN USUARIO MBA"
        case .iconoMilenium: "DATOS PARA CREAR UN ICONO MILENIUM"
        case .iconoMBA: "DATOS PARA CREAR UN ICONO MBA"
        }
    }
}

@MainActor
final class CreateTicketViewModel: ObservableObject {
    @Published var tipoTicket = "sistemas"
    @Published var titulo = ""
    @Published var categoria = ""
    @Published var prioridad = "media"
    @Published var empresa = "NOVICOMPU"
    @Published var descripcion = ""
    @Published var cargo = ""
    @Published var nombresCompletos = ""
    @Published var cedula = ""
    @Published var telefono = ""
    @Published var correoTienda = ""
    @Published var grupoMilenium = ""
    @Published var accesoParecido = ""
    @Published var observaciones = ""
    @Published var mbaIcono = ""
    @Published var mbaRuta = ""
    @Published var mbaDocumentos = ""
    @Published var mbaDetalle = ""
    @Published var mbaAccion = ""
    @Published var tiendaId: Int?
    @Published var files: [UploadFile] = []
    @Published private(set) var catalog: CatalogResponse?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var isSuccess = false

    let prioridades = ["baja", "media", "alta", "urgente"]

    var categorias: [String] {
        guard let catalog else { return [] }
        if tipoTicket == "soporte_tecnico" { return catalog.categoriasSoporte }
        return catalog.categoriasSistemas.flatMap(\.categorias)
    }

    var tiendas: [StoreDto] { catalog?.tiendas ?? [] }

    var formulario: FormularioTicket {
        if categoria == "Casos MBA3" { return .casoMBA3 }
        if variante != nil { return .datosEspecificos }
        return .descripcionEstandar
    }

    var variante: VarianteEspecifica? {
        let normalized = categoria.lowercased()
        if categoria == "Creación vendedor MBA" || normalized.contains("crear un vendedor") || normalized.contains("vendedor mba") { return .crearVendedor }
        if categoria == "Creación de usuario MBA" || normalized.contains("crear un usuario mba") || normalized.contains("usuario mba") { return .crearUsuarioMBA }
        if categoria == "Creación icono Millenium" || normalized.contains("icono milenium") || normalized.contains("milenium") { return .iconoMilenium }
        if categoria == "Colocación / Creación icono MBA" || normalized.contains("icono mba") { return .iconoMBA }
        return nil
    }

    func loadCatalog(user: UserDto? = nil) async {
        do {
            catalog = try await ApiService.shared.getCatalogo()
            if tiendaId == nil { tiendaId = tiendas.first?.id }
            if telefono.isEmpty { telefono = user?.telefono ?? "" }
            if correoTienda.isEmpty { correoTienda = user?.correo ?? "" }
            if empresa == "NOVICOMPU" { empresa = user?.empresaOrigen ?? empresa }
            if tiendaId == nil { tiendaId = user?.tienda?.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addFiles(_ urls: [URL]) {
        for url in urls {
            do {
                files.append(try AdjuntoFactory.desdeURL(url))
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
                return
            }
        }
    }

    func removeFile(at index: Int) {
        guard files.indices.contains(index) else { return }
        files.remove(at: index)
    }

    func submit(user: UserDto) async -> Bool {
        guard !isLoading else { return false }
        guard !categoria.isEmpty else { errorMessage = "Selecciona una categoría."; return false }
        guard let store = tiendas.first(where: { $0.id == tiendaId }) else {
            errorMessage = "Selecciona la tienda o sucursal afectada."
            return false
        }
        if let missing = firstMissingField {
            errorMessage = missing
            return false
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        let finalTitle = titulo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? generatedTitle(store: store) : titulo.trimmingCharacters(in: .whitespacesAndNewlines)
        let fields = [
            "tipo_ticket": tipoTicket,
            "categoria": categoria,
            "prioridad": prioridad,
            "empresa_origen": empresa,
            "titulo": finalTitle,
            "descripcion": compiledDescription(store: store, userName: user.nombreMostrable),
            "tienda_nombre": "\(store.codigo) - \(store.nombre)",
            "sucursal_cliente_id": String(store.id),
            "solicitante_nombre": user.nombreMostrable
        ]
        do {
            let response = try await ApiService.shared.createTicket(fields: fields, files: files)
            guard response.ok else {
                errorMessage = response.error ?? "No se pudo registrar el ticket."
                return false
            }
            isSuccess = true
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func reset() {
        titulo = ""
        categoria = ""
        prioridad = "media"
        descripcion = ""
        cargo = ""
        nombresCompletos = ""
        cedula = ""
        observaciones = ""
        mbaIcono = ""
        mbaRuta = ""
        mbaDocumentos = ""
        mbaDetalle = ""
        mbaAccion = ""
        files = []
        isSuccess = false
        errorMessage = nil
    }

    private var firstMissingField: String? {
        switch formulario {
        case .casoMBA3:
            if mbaIcono.isEmpty { return "Ingresa el ícono de acceso del caso MBA3." }
            if mbaRuta.isEmpty { return "Ingresa la ruta o módulo de MBA3." }
            if mbaDetalle.isEmpty { return "Describe detalladamente el problema en MBA3." }
            if mbaAccion.isEmpty { return "Indica qué acción requiere que resuelva Sistemas." }
        case .datosEspecificos:
            if cargo.isEmpty { return "Ingresa el cargo en la sucursal." }
            if nombresCompletos.isEmpty { return "Ingresa los nombres completos." }
            if cedula.isEmpty { return "Ingresa el número de cédula." }
            if telefono.isEmpty { return "Ingresa el teléfono corporativo o celular." }
            if correoTienda.isEmpty { return "Ingresa el correo corporativo de la tienda." }
            if variante == .iconoMilenium && grupoMilenium.isEmpty { return "Ingresa el grupo de Milenium." }
            if variante == .iconoMBA && accesoParecido.isEmpty { return "Indica un usuario de referencia." }
        case .descripcionEstandar:
            if descripcion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "Describe detalladamente el requerimiento." }
        }
        return nil
    }

    private func generatedTitle(store: StoreDto) -> String {
        switch formulario {
        case .casoMBA3: "Caso MBA3 - \(store.nombre)"
        case .datosEspecificos: "\(categoria) - \(nombresCompletos.isEmpty ? store.nombre : nombresCompletos)"
        case .descripcionEstandar: "\(categoria) - \(store.nombre)"
        }
    }

    private func compiledDescription(store: StoreDto, userName: String) -> String {
        let thick = "========================================"
        let thin = "----------------------------------------"
        switch formulario {
        case .descripcionEstandar:
            return descripcion.trimmingCharacters(in: .whitespacesAndNewlines)
        case .casoMBA3:
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "es_EC")
            formatter.dateFormat = "dd/MM/yyyy"
            return """
            \(thick)
            REGISTRO OFICIAL DE CASO MBA3
            \(thick)
            • Fecha de Registro: \(formatter.string(from: Date()))
            • Tienda / Sucursal: \(store.codigo) - \(store.nombre)
            • Usuario que Reporta: \(userName)
            • Ícono de Acceso: \(mbaIcono.trimmingCharacters(in: .whitespacesAndNewlines))
            • Ruta de Acceso / Módulo: \(mbaRuta.trimmingCharacters(in: .whitespacesAndNewlines))
            • Documentos / Datos Afectados: \(mbaDocumentos.isEmpty ? "No especificado" : mbaDocumentos)
            \(thin)
            DESCRIPCIÓN DETALLADA DEL PROBLEMA:
            \(mbaDetalle.trimmingCharacters(in: .whitespacesAndNewlines))
            \(thin)
            ACCIÓN REQUERIDA:
            \(mbaAccion.trimmingCharacters(in: .whitespacesAndNewlines))
            \(thick)
            """
        case .datosEspecificos:
            let extra: String
            switch variante {
            case .iconoMilenium: extra = "• Grupo de Milenium: \(grupoMilenium)\n"
            case .iconoMBA: extra = "• Acceso parecido a: \(accesoParecido)\n"
            default: extra = ""
            }
            return """
            \(thick)
            \(variante?.tituloCaso ?? "DATOS ESPECÍFICOS")
            \(thick)
            • Cargo en la sucursal: \(cargo)
            • Nombres Completos: \(nombresCompletos.uppercased())
            • Número de Cédula: \(cedula)
            • Teléfono corporativo: \(telefono)
            • Correo corporativo: \(correoTienda)
            • Sucursal: \(store.codigo) - \(store.nombre)
            \(extra)
            \(observaciones.isEmpty ? "" : "\(thin)\nOBSERVACIONES ADICIONALES:\n\(observaciones)\n")\(thick)
            """
        }
    }
}
#endif