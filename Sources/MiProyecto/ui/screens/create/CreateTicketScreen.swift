#if canImport(SwiftUI)
import SwiftUI
import UniformTypeIdentifiers

struct CreateTicketScreen: View {
    let user: UserDto
    let onCreated: () -> Void
    @StateObject private var viewModel = CreateTicketViewModel()
    @State private var showingFilePicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Tipo de requerimiento") {
                    Picker("Tipo", selection: $viewModel.tipoTicket) {
                        Text("Sistemas").tag("sistemas")
                        Text("Soporte técnico").tag("soporte_tecnico")
                    }
                    .pickerStyle(.segmented)
                    Picker("Categoría", selection: $viewModel.categoria) {
                        Text("Selecciona").tag("")
                        ForEach(viewModel.categorias, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    Picker("Prioridad", selection: $viewModel.prioridad) {
                        ForEach(viewModel.prioridades, id: \.self) { item in
                            Text(item.capitalized).tag(item)
                        }
                    }
                }

                Section("Solicitud") {
                    TextField("Título (opcional)", text: $viewModel.titulo)
                    Picker("Empresa", selection: $viewModel.empresa) {
                        Text("Novicompu").tag("NOVICOMPU")
                        Text("ENV").tag("ENV")
                        Text("Otros").tag("OTRO")
                    }
                    Picker("Tienda", selection: $viewModel.tiendaId) {
                        Text("Selecciona tienda").tag(Int?.none)
                        ForEach(viewModel.tiendas) { store in
                            Text("\(store.codigo) · \(store.nombre)").tag(Int?.some(store.id))
                        }
                    }
                    switch viewModel.formulario {
                    case .casoMBA3:
                        TextField("Ícono de acceso", text: $viewModel.mbaIcono)
                        TextField("Ruta o módulo MBA3", text: $viewModel.mbaRuta)
                        TextField("Documentos o datos afectados", text: $viewModel.mbaDocumentos)
                        TextField("Descripción detallada", text: $viewModel.mbaDetalle, axis: .vertical).lineLimit(4...8)
                        TextField("Acción requerida", text: $viewModel.mbaAccion, axis: .vertical).lineLimit(3...6)
                    case .datosEspecificos:
                        Picker("Cargo", selection: $viewModel.cargo) {
                            Text("Selecciona cargo").tag("")
                            ForEach(["Vendedor / Asesor Comercial", "Cajero / Vendedor", "Administrador de Tienda", "Subadministrador de Tienda", "Bodeguero", "Técnico de Servicio"], id: \.self) { Text($0).tag($0) }
                        }
                        TextField("Nombres completos", text: $viewModel.nombresCompletos)
                        TextField("Número de cédula", text: $viewModel.cedula).keyboardType(.numberPad)
                        TextField("Teléfono corporativo", text: $viewModel.telefono).keyboardType(.phonePad)
                        TextField("Correo corporativo", text: $viewModel.correoTienda).keyboardType(.emailAddress).textInputAutocapitalization(.never)
                        if viewModel.variante == .iconoMilenium {
                            Picker("Grupo Milenium", selection: $viewModel.grupoMilenium) {
                                ForEach(["Ventas", "Administración", "Caja / Facturación", "Bodega / Inventario"], id: \.self) { Text($0).tag($0) }
                            }
                        }
                        if viewModel.variante == .iconoMBA { TextField("Acceso parecido a", text: $viewModel.accesoParecido) }
                        TextField("Observaciones", text: $viewModel.observaciones, axis: .vertical).lineLimit(3...6)
                    case .descripcionEstandar:
                        TextField("Describe el requerimiento", text: $viewModel.descripcion, axis: .vertical)
                            .lineLimit(5...10)
                    }
                }

                Section("Adjuntos") {
                    ForEach(viewModel.files.indices, id: \.self) { index in
                        HStack {
                            Label(viewModel.files[index].fileName, systemImage: "paperclip")
                            Spacer()
                            Button("Quitar", systemImage: "xmark", role: .destructive) {
                                viewModel.removeFile(at: index)
                            }
                            .labelStyle(.iconOnly)
                        }
                    }
                    Button("Agregar archivo", systemImage: "plus") { showingFilePicker = true }
                }

                if let errorMessage = viewModel.errorMessage {
                    Section { Text(errorMessage).foregroundStyle(.red) }
                }

                Section {
                    Button {
                        Task {
                            if await viewModel.submit(user: user) {
                                viewModel.reset()
                                onCreated()
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isLoading { ProgressView() }
                            Text("Registrar ticket").fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .navigationTitle("Crear ticket")
            .fileImporter(isPresented: $showingFilePicker, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
                guard case .success(let urls) = result else { return }
                for url in urls {
                    viewModel.addFiles([url])
                }
            }
            .task { await viewModel.loadCatalog(user: user) }
            .onChange(of: viewModel.tipoTicket) { _, _ in viewModel.categoria = "" }
        }
    }
}
#endif