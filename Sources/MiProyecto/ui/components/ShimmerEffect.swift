#if canImport(SwiftUI)
import SwiftUI

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    LinearGradient(colors: [.clear, .white.opacity(0.35), .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: proxy.size.width * 0.6)
                        .offset(x: proxy.size.width * phase)
                }
                .clipped()
            }
            .task {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) { phase = 1.8 }
            }
    }
}

extension View {
    func shimmerEffect() -> some View { modifier(ShimmerEffect()) }
}
#endif 