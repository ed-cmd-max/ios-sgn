import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum FotoPerfil {
    static func urlSegura(_ value: String?) -> URL? {
        guard let value, UrlSegura.esUrlWeb(value) else { return nil }
        return URL(string: value)
    }

    #if canImport(UIKit)
    static func prepararJPEG(_ data: Data, maxDimension: CGFloat = 1024) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let longestSide = max(image.size.width, image.size.height)
        let ratio = min(1, maxDimension / longestSide)
        let size = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
        return UIGraphicsImageRenderer(size: size).jpegData(withCompressionQuality: 0.82) { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    #endif
}