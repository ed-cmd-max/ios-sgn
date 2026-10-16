#if canImport(SwiftUI)
import SwiftUI

struct TicketListScreen: View {
    let user: AuthUser
    @StateObject private var viewModel: TicketListViewModel

    init(user: UserDto) {
        self.user = user
        _viewModel = StateObject(wrappedValue: TicketListViewModel(user: user))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.filters) { option in
                            Button(option.title) { viewModel.filter = option }
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(viewModel.filter == option ? Color.accentColor.opacity(0.16) : Color.secondary.opacity(0.08))
                                .clipShape(Capsule())
                                .accessibilityAddTraits(viewModel.filter == option ? .isSelected : [])
                        }
                    }
                }
                .padding(.horizontal)

                if let stats = viewModel.stats, viewModel.isTechnician {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            SgnKpiCard(title: "Total", value: viewModel.total)
                            SgnKpiCard(title: "Abiertos", value: stats.abiertos)
                            SgnKpiCard(title: "Urgentes", value: stats.urgentes, tint: SgnColor.danger)
                            SgnKpiCard(title: "Sin asignar", value: stats.sinAsignar, tint: SgnColor.warning)
                        }
                        .padding(.horizontal)
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    ContentUnavailableView {
                        Label("No se cargaron los tickets", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button("Reintentar") { Task { await viewModel.loadTickets() } }
                    }
                } else if viewModel.visibleTickets.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView("Sin tickets", systemImage: "checkmark.circle")
                } else {
                    List(viewModel.visibleTickets) { ticket in
                        NavigationLink(value: ticket.id) {
                            VStack(alignment: .leading, spacing: 7) {
                                HStack {
                                    Text(ticket.displayCode)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(ticket.prioridad.capitalized)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(ticket.prioridad.lowercased() == "urgente" ? .red : .secondary)
                                }
                                Text(ticket.titulo.isEmpty ? "Sin título" : ticket.titulo)
                                    .font(.headline)
                                HStack(spacing: 8) {
                                    Text(ticket.estado.replacingOccurrences(of: "_", with: " ").capitalized)
                                    Text("·")
                                    Text(ticket.categoria)
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                        }
                        .onAppear {
                            if ticket.id == viewModel.visibleTickets.last?.id {
                                Task { await viewModel.loadMore() }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await viewModel.loadTickets() }
                    .overlay {
                        if viewModel.isLoading { ProgressView().controlSize(.large) }
                    }
                }
            }
            .navigationTitle("Tickets")
            .navigationDestination(for: Int.self) { ticketId in
                TicketDetailScreen(ticketId: ticketId, user: user)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text(user.nombreMostrable)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .searchable(text: $viewModel.query, prompt: "Buscar tickets")
            .task(id: "\(viewModel.filter.rawValue)|\(viewModel.query)") {
                try? await Task.sleep(nanoseconds: 350_000_000)
                guard !Task.isCancelled else { return }
                await viewModel.loadTickets()
            }
        }
    }
}
#endif