#if canImport(SwiftUI)
import SwiftUI

struct AvatarUsuario: View {
    let nombre: String
    var fotoURL: URL?
    var size: CGFloat = 40

    var body: some View {
        Group {
            if let fotoURL {
                AsyncImage(url: fotoURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    initials
                }
            } else {
                initials
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityLabel(nombre)
    }

    private var initials: some View {
        Text(String(nombre.split(separator: " ").prefix(2).compactMap(\.first)))
            .font(.system(size: size * 0.34, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(SgnColor.primary)
    }
}
#endif