import XCTest

final class ScreenshotsTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    @MainActor
    func testCaptureAllScreens() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
        app.launch()

        let outputDir = URL(fileURLWithPath: "/Users/runner/work/ios-sgn/ios-sgn/screenshots")
        try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        func capture(name: String) {
            sleep(2) // Esperar a que renderice la animación/vista
            let screenshot = XCUIScreen.main.screenshot()

            let fileURL = outputDir.appendingPathComponent("\(name).png")
            try? screenshot.pngRepresentation.write(to: fileURL)

            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
        }

        // 1. Capturar Login
        capture(name: "01_LoginScreen")

        // 2. Interactuar con el Login (Rellenar campos si existen y presionar entrar)
        let textFields = app.textFields
        if textFields.count > 0 {
            let userField = textFields.element(boundBy: 0)
            if userField.exists {
                userField.tap()
                userField.typeText("test@novitec.ec")
            }
        }

        let secureFields = app.secureTextFields
        if secureFields.count > 0 {
            let passField = secureFields.element(boundBy: 0)
            if passField.exists {
                passField.tap()
                passField.typeText("Password123")
            }
        }

        // Buscar botón de acceso de forma general o por tipo de botón
        let buttons = app.buttons
        for i in 0..<buttons.count {
            let btn = buttons.element(boundBy: i)
            if btn.exists && btn.isHittable {
                let label = btn.label.lowercased()
                if label.contains("ingresar") || label.contains("entrar") || label.contains("iniciar") || label.contains("login") {
                    btn.tap()
                    break
                }
            }
        }

        // Si no encontró por etiqueta, presiona el primer botón disponible como fallback
        if buttons.count > 0 && !app.tabBars.firstMatch.exists {
            let fallbackBtn = buttons.firstMatch
            if fallbackBtn.exists && fallbackBtn.isHittable {
                fallbackBtn.tap()
            }
        }

        // 3. Capturar Pantalla Principal / Tickets tras el login
        capture(name: "02_TicketsScreen")

        // 4. Intentar ir a Crear Ticket (Buscar botón de "+" o "Nuevo")
        let createBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'crear' OR label CONTAINS[c] 'nuevo' OR label CONTAINS[c] '+'")).firstMatch
        if createBtn.exists && createBtn.isHittable {
            createBtn.tap()
            capture(name: "03_CreateTicketScreen")
            let backBtn = app.navigationBars.buttons.firstMatch
            if backBtn.exists { backBtn.tap() }
        }

        // 5. Intentar entrar al detalle de un ticket si la lista tiene elementos
        let cells = app.cells
        if cells.count > 0 {
            let firstCell = cells.firstMatch
            if firstCell.exists && firstCell.isHittable {
                firstCell.tap()
                capture(name: "04_TicketDetailScreen")

                let chatBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'chat'")).firstMatch
                if chatBtn.exists && chatBtn.isHittable {
                    chatBtn.tap()
                    capture(name: "05_ChatScreen")
                    let backChat = app.navigationBars.buttons.firstMatch
                    if backChat.exists { backChat.tap() }
                }
                let backDetail = app.navigationBars.buttons.firstMatch
                if backDetail.exists { backDetail.tap() }
            }
        }

        // 6. Navegación por pestañas inferiores (TabBars) si existen
        let tabButtons = app.tabBars.buttons
        for i in 0..<tabButtons.count {
            let tab = tabButtons.element(boundBy: i)
            if tab.exists && tab.isHittable {
                tab.tap()
                let tabName = tab.label.isEmpty ? "Tab_\(i+1)" : tab.label
                capture(name: "Tab_\(tabName)")
            }
        }
    }
}
