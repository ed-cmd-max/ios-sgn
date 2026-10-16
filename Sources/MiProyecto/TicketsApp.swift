#if canImport(SwiftUI)
import SwiftUI

@main
struct TicketsApp: App {
    var body: some Scene {
        WindowGroup { MainActivity() }
    }
}
#else
struct TicketsApp {
    static func main() {
        print("SGN Tickets: abre este código en un proyecto iOS con Xcode para ejecutar la interfaz SwiftUI.")
    }
}
#endif