#if canImport(SwiftUI)
import SwiftUI

struct MainActivity: View {
    var body: some View {
        LoginScreen()
            .sgnTheme()
            .task { GlobalChatMonitor.shared.start() }
    }
}
#endif