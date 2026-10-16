import Foundation

enum UrlSegura {
    static func esUrlWeb(_ value: String) -> Bool {
        guard let url = URL(string: value), url.scheme == "https" else { return false }
        return url.host == "novitec.com.ec"
    }

    static func validar(_ value: String) throws -> URL {
        guard esUrlWeb(value), let url = URL(string: value) else {
            throw URLError(.badURL)
        }
        return url
    }
}