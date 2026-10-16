#if canImport(SwiftUI)
import SwiftUI

struct SgnTheme: ViewModifier {
    @AppStorage("sgn_dark_theme") private var isDark = false

    func body(content: Content) -> some View {
        content.preferredColorScheme(isDark ? .dark : .light)
    }
}

extension View {
    func sgnTheme() -> some View { modifier(SgnTheme()) }
}
#endif