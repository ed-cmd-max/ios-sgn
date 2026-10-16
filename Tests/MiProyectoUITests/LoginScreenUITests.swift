import XCTest

final class LoginScreenUITests: XCTestCase {
    @MainActor
    func testLoginScreenScreenshot() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        XCTAssertTrue(app.staticTexts["SGN Tickets"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.textFields["Usuario o correo"].exists)
        XCTAssertTrue(app.secureTextFields["Contraseña"].exists)
        XCTAssertTrue(app.buttons["Iniciar sesión"].exists)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "SGN Tickets - Login"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
