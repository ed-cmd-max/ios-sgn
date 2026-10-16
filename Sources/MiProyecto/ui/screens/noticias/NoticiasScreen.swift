#if canImport(SwiftUI)
import SwiftUI

struct NoticiasScreen: View {
    let user: UserDto
    @StateObject private var viewModel = NoticiasViewModel()
    @State private var showingForm = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.noticias.isEmpty {
                    ProgressView("Cargando noticias…")
                } else if viewModel.noticias.isEmpty {
                    ContentUnavailableView("Sin noticias", systemImage: "newspaper")
                } else {
                    List(viewModel.noticias) { noticia in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(noticia.severidad.capitalized).font(.caption.weight(.semibold)).foregroundStyle(.orange)
                                Spacer()
                                Text(noticia.fechaHora).font(.caption).foregroundStyle(.secondary)
                            }
                            Text(noticia.titulo).font(.headline)
                            Text(noticia.descripcion).font(.subheadline).foregroundStyle(.secondary)
                            Text("\(noticia.autor) · \(noticia.estado.capitalized)").font(.caption).foregroundStyle(.tertiary)
                            if user.puedeCrearNoticias && noticia.esIncidenciaActiva {
                                Button("Marcar resuelta", systemImage: "checkmark.circle") { Task { await viewModel.resolve(noticia) } }
                                    .font(.footnote)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    .listStyle(.plain)
                    .refreshable { await viewModel.load() }
                }
            }
            .navigationTitle("Noticias")
            .toolbar {
                if user.puedeCrearNoticias {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Nueva noticia", systemImage: "plus") { showingForm = true }
                            .labelStyle(.iconOnly)
                    }
                }
            }
            .sheet(isPresented: $showingForm) {
                NoticiaFormulario(opciones: viewModel.opciones) { fields in await viewModel.publish(fields) }
            }
            .task { await viewModel.load() }
            .overlay(alignment: .bottom) {
                if let error = viewModel.errorMessage {
                    Text(error).font(.footnote).foregroundStyle(.red).padding().background(.regularMaterial)
                }
            }
        }
    }
}
#endif