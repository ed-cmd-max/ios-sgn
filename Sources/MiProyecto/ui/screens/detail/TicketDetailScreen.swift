#if canImport(SwiftUI)
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class TicketDetailViewModel: ObservableObject {
    @Published private(set) var ticket: TicketDto?
    @Published private(set) var isTechnician = false
    @Published private(set) var isLoading = true
    @Published private(set) var isSaving = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var technicians: [UserDto] = []
    @Published private(set) var document: DocumentosResponse?

    func load(id: Int) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await ApiService.shared.getTicketDetail(id: id)
            guard result.ok, let loadedTicket = result.ticket else {
                errorMessage = result.error ?? "No se pudo cargar el ticket."
                return
            }
            ticket = loadedTicket
            isTechnician = result.esTecnico
            if result.esTecnico { await loadTechnicians() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadTechnicians() async {
        do { technicians = try await ApiService.shared.getCatalogo().tecnicosSistemas }
        catch { technicians = [] }
    }

    func changeStatus(_ status: String, solution: String = "", evidence: UploadFile? = nil) async {
        guard let ticket else { return }
        await runAction {
            try await ApiService.shared.cambiarEstado(id: ticket.id, fields: ["estado": status, "solucion": solution], evidence: evidence)
        }
    }

    func assign(to technicianId: Int) async {
        guard let ticket else { return }
        await runAction { try await ApiService.shared.asignarTicket(id: ticket.id, technicianId: technicianId) }
    }

    func rate(_ rating: Int, comment: String) async {
        guard let ticket else { return }
        await runAction { try await ApiService.shared.calificarTicket(id: ticket.id, rating: rating, comment: comment) }
    }

    func reopen(reason: String) async {
        guard let ticket else { return }
        await runAction { try await ApiService.shared.reabrirTicket(id: ticket.id, reason: reason) }
    }

    func loadDocuments() async {
        guard let ticket else { return }
        do { document = try await ApiService.shared.getDocumentos(ticketId: ticket.id) }
        catch { errorMessage = error.localizedDescription }
    }

    func setError(_ message: String) { errorMessage = message }

    private func runAction(_ action: () async throws -> GenericApiResponse) async {
        guard let ticket else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            let result = try await action()
            guard result.ok else { errorMessage = result.error ?? "No se pudo actualizar el ticket."; return }
            await load(id: ticket.id)
        } catch { errorMessage = error.localizedDescription }
    }
}

struct TicketDetailScreen: View {
    let ticketId: Int
    let user: UserDto
    @StateObject private var viewModel = TicketDetailViewModel()
    @State private var solution = ""
    @State private var rating = 5
    @State private var comment = ""
    @State private var reopenReason = ""
    @State private var evidence: UploadFile?
    @State private var showingEvidencePicker = false
    @State private var showingRating = false
    @State private var showingReopen = false
    @State private var showingAssignment = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Cargando ticket…")
            } else if let ticket = viewModel.ticket {
                List {
                    Section {
                        LabeledContent("Código", value: ticket.displayCode)
                        LabeledContent("Estado", value: ticket.estado.replacingOccurrences(of: "_", with: " ").capitalized)
                        LabeledContent("Prioridad", value: ticket.prioridad.capitalized)
                        LabeledContent("Categoría", value: ticket.categoria)
                        LabeledContent("Tienda", value: ticket.tiendaNombre ?? "No especificada")
                    }
                    Section("Descripción") { Text(ticket.descripcion) }
                    if let solution = ticket.solucion, !solution.isEmpty {
                        Section("Solución") { Text(solution) }
                    }
                    Section("Acciones") {
                        NavigationLink {
                            ChatScreen(ticketId: ticket.id, ticketCode: ticket.displayCode, user: user)
                                            if let attachments = ticket.adjuntos, !attachments.isEmpty {
                                                Section("Adjuntos") {
                                                    ForEach(attachments) { attachment in AdjuntosAbrir(attachment: attachment) }
                                                }
                                            }
                                            if viewModel.isTechnician && user.esTecnicoReal {
                                                Section("Evidencia de resolución") {
                                                    if let evidence { Label(evidence.fileName, systemImage: "paperclip") }
                                                    Button(evidence == nil ? "Adjuntar evidencia" : "Cambiar evidencia", systemImage: "paperclip") {
                                                        showingEvidencePicker = true
                                                    }
                                                }
                                            }
                        } label: {
                            Label("Abrir chat", systemImage: "bubble.left.and.bubble.right")
                        }
                        Button("Documentos del ticket", systemImage: "doc.text") {
                            Task { await viewModel.loadDocuments() }
                        }
                        if viewModel.isTechnician && user.esTecnicoReal {
                            TextField("Solución (opcional)", text: $solution, axis: .vertical)
                            Menu("Cambiar estado") {
                                ForEach(["en_proceso", "en_espera", "en_mba", "resuelto", "cerrado"], id: \.self) { status in
                                    Button(status.replacingOccurrences(of: "_", with: " ").capitalized) {
                                        Task { await viewModel.changeStatus(status, solution: solution, evidence: evidence) }
                                    }
                                }
                            }
                            Button("Asignar técnico", systemImage: "person.badge.plus") { showingAssignment = true }
                        } else {
                            if ticket.estado == "resuelto" && ticket.calificacion == nil {
                                Button("Calificar ticket", systemImage: "star") { showingRating = true }
                            }
                            if ["resuelto", "cerrado"].contains(ticket.estado) {
                                Button("Reabrir ticket", systemImage: "arrow.uturn.backward") { showingReopen = true }
                            }
                        }
                    }
                    if let document = viewModel.document {
                        Section("Documentos") {
                            if let url = document.imprimirUrl, UrlSegura.esUrlWeb(url), let parsed = URL(string: url) { Link("Ficha para imprimir", destination: parsed) }
                            if let url = document.wordMbaUrl, UrlSegura.esUrlWeb(url), let parsed = URL(string: url) { Link("Documento MBA", destination: parsed) }
                        }
                    }
                    if let error = viewModel.errorMessage { Section { Text(error).foregroundStyle(.red) } }
                }
                .refreshable { await viewModel.load(id: ticketId) }
                .overlay { if viewModel.isSaving { ProgressView() } }
                .confirmationDialog("Asignar técnico", isPresented: $showingAssignment) {
                    ForEach(viewModel.technicians) { technician in
                        Button(technician.nombreMostrable) { Task { await viewModel.assign(to: technician.id) } }
                    }
                }
                .alert("Calificar", isPresented: $showingRating) {
                    Picker("Calificación", selection: $rating) {
                        ForEach(1...5, id: \.self) { Text("\($0) estrellas").tag($0) }
                    }
                    TextField("Comentario", text: $comment)
                    Button("Guardar") { Task { await viewModel.rate(rating, comment: comment) } }
                    Button("Cancelar", role: .cancel) { }
                }
                .alert("Reabrir ticket", isPresented: $showingReopen) {
                    TextField("Motivo", text: $reopenReason)
                    Button("Reabrir") { Task { await viewModel.reopen(reason: reopenReason) } }
                    Button("Cancelar", role: .cancel) { }
                }
            } else {
                ContentUnavailableView("No se pudo cargar el ticket", systemImage: "exclamationmark.triangle", description: Text(viewModel.errorMessage ?? "Intenta nuevamente."))
            }
        }
        .navigationTitle(viewModel.ticket?.displayCode ?? "Detalle")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load(id: ticketId) }
        .fileImporter(isPresented: $showingEvidencePicker, allowedContentTypes: [.item]) { result in
            guard case .success(let url) = result else { return }
            do { evidence = try AdjuntoFactory.desdeURL(url, fieldName: AdjuntoFactory.campoEvidencia) }
            catch { viewModel.setError(error.localizedDescription) }
        }
    }

}
#endif