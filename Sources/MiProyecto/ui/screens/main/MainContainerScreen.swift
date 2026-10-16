#if canImport(SwiftUI)
import SwiftUI

struct MainContainerScreen: View {
    let user: UserDto
    let onLogout: () -> Void
    @State private var selectedTab = 0
    @State private var showingAudit = false
    @State private var showingSolicitantes = false

    var body: some View {
        TabView(selection: $selectedTab) {
            TicketListScreen(user: user)
                .tabItem { Label("Tickets", systemImage: "ticket") }
                .tag(0)

            TicketListScreen(user: user)
                .tabItem { Label("Buscar", systemImage: "magnifyingglass") }
                .tag(1)

            CreateTicketScreen(user: user) {
                selectedTab = 0
            }
            .tabItem { Label("Crear", systemImage: "plus.circle.fill") }
            .tag(2)

            NoticiasScreen(user: user)
                .tabItem { Label("Noticias", systemImage: "newspaper") }
                .tag(3)

            ProfileScreen(
                user: user,
                onLogout: onLogout,
                onOpenAudit: { showingAudit = true },
                onOpenSolicitantes: { showingSolicitantes = true }
            )
            .tabItem { Label("Perfil", systemImage: "person.crop.circle") }
            .tag(4)
        }
        .sheet(isPresented: $showingAudit) { AuditoriaScreen() }
        .sheet(isPresented: $showingSolicitantes) { SolicitantesScreen(user: user) }
    }
}
#endif