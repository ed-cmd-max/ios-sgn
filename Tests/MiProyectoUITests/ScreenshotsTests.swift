import XCTest

final class ScreenshotsUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    @MainActor
    func testCaptureAllScreens() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
        app.launch()

        // Directorio en el runner donde se almacenarán las imágenes PNG
        let outputDir = URL(fileURLWithPath: "/Users/runner/work/ios-sgn/ios-sgn/screenshots")
        try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        func capture(name: String) {
            sleep(2)
            let screenshot = XCUIScreen.main.screenshot()

            // 1. Guardar como archivo PNG en la carpeta de capturas
            let fileURL = outputDir.appendingPathComponent("\(name).png")
            try? screenshot.pngRepresentation.write(to: fileURL)

            // 2. Adjuntar al reporte de resultados de Xcode
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
        }

        // 1. Pantalla de Login
        capture(name: "01_LoginScreen")

        // 2. Intentar ingresar a la pantalla principal
        let loginBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'iniciar' OR label CONTAINS[c] 'login' OR label CONTAINS[c] 'entrar'")).firstMatch
        if loginBtn.exists && loginBtn.isHittable {
            loginBtn.tap()
        }
        capture(name: "02_TicketsScreen")

        // 3. Crear Ticket
        let createBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'crear' OR label CONTAINS[c] 'nuevo' OR label CONTAINS[c] '+'")).firstMatch
        if createBtn.exists && createBtn.isHittable {
            createBtn.tap()
            capture(name: "03_CreateTicketScreen")
            let backBtn = app.navigationBars.buttons.firstMatch
            if backBtn.exists { backBtn.tap() }
        }

        // 4. Detalle de Ticket
        let ticketCell = app.cells.firstMatch
        if ticketCell.exists && ticketCell.isHittable {
            ticketCell.tap()
            capture(name: "04_TicketDetailScreen")

            // 5. Chat del Ticket
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

        // 6. Pantalla de Noticias
        let noticiasTab = app.tabBars.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'noticia'")).firstMatch
        if noticiasTab.exists && noticiasTab.isHittable {
            noticiasTab.tap()
            capture(name: "06_NoticiasScreen")
        }

        // 7. Pantalla de Notificaciones
        let notifBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'notificaci' OR label CONTAINS[c] 'alerta'")).firstMatch
        if notifBtn.exists && notifBtn.isHittable {
            notifBtn.tap()
            capture(name: "07_NotificationsScreen")
            let closeBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'cerrar' OR label CONTAINS[c] 'atrás'")).firstMatch
            if closeBtn.exists { closeBtn.tap() }
        }

        // 8. Pantalla de Perfil
        let perfilTab = app.tabBars.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'perfil' OR label CONTAINS[c] 'usuario'")).firstMatch
        if perfilTab.exists && perfilTab.isHittable {
            perfilTab.tap()
            capture(name: "08_ProfileScreen")
        }
    }
}