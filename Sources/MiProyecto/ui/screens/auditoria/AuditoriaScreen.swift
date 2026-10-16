#if canImport(SwiftUI)
import SwiftUI

struct AuditoriaScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var response: AuditoriaResponse?
    @State private var query = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && response == nil { ProgressView("Cargando auditoría…") }
                else if let response {
                    List {
                        if let kpis = response.kpis {
                            Section("Resumen") {
                                LabeledContent("Tickets", value: String(kpis.totalTickets))
                                LabeledContent("Abiertos", value: String(kpis.abiertos))
                                LabeledContent("Resueltos", value: String(kpis.resueltos))
                                LabeledContent("Resolución", value: "\(Int(kpis.tasaResolucion))%")
                            }
                        }
                        Section("Tickets") {
                            ForEach(response.tickets) { ticket in
                                NavigationLink {
                                    AuditoriaDetalleScreen(ticketId: ticket.id)
                                } label: {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(ticket.codigoTicket).font(.caption).foregroundStyle(.secondary)
                                        Text(ticket.titulo ?? "Sin título").font(.headline)
                                        Text("\(ticket.estado ?? "") · \(ticket.tiendaNombre ?? "")")
                                            .font(.subheadline).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .searchable(text: $query, prompt: "Buscar auditoría")
                    .refreshable { await load() }
                } else {
                    ContentUnavailableView("Auditoría no disponible", systemImage: "chart.bar.xaxis", description: Text(errorMessage ?? "Intenta nuevamente."))
                }
            }
            .navigationTitle("Auditoría")
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Cerrar") { dismiss() } } }
            .task(id: query) {
                try? await Task.sleep(nanoseconds: 300_000_000)
                await load()
            }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do { response = try await ApiService.shared.getAuditoria(query: query) }
        catch { errorMessage = error.localizedDescription }
    }
}

private struct AuditoriaDetalleScreen: View {
    let ticketId: Int
    @State private var detail: AuditoriaDetalleResponse?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let detail, let ticket = detail.ticket {
                List {
                    Section("Ticket") {
                        LabeledContent("Código", value: ticket.displayCode)
                        LabeledContent("Estado", value: ticket.estado.capitalized)
                        LabeledContent("Categoría", value: ticket.categoria)
                        LabeledContent("Prioridad", value: ticket.prioridad.capitalized)
                    }
                    Section("Personas y tienda") {
                        LabeledContent("Solicitante", value: detail.solicitanteNombre ?? "No disponible")
                        LabeledContent("Asignado a", value: detail.asignadoNombre ?? "Sin asignar")
                        LabeledContent("Tienda", value: detail.tiendaNombre ?? "No disponible")
                    }
                    Section("Solución") { Text(detail.solucionTexto ?? ticket.solucion ?? "Sin solución registrada") }
                }
            } else if let errorMessage {
                ContentUnavailableView("Detalle no disponible", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
            } else {
                ProgressView("Cargando detalle…")
            }
        }
        .navigationTitle("Detalle auditable")
        .task {
            do { detail = try await ApiService.shared.getAuditoriaDetalle(id: ticketId) }
            catch { errorMessage = error.localizedDescription }
        }
    }
}
#endif