import Foundation

enum ApiClient {
    static let baseURL = URL(string: "https://novitec.com.ec/sgn/")!

    static func endpoint(_ components: String...) -> URL {
        components.reduce(baseURL) { url, component in
            url.appendingPathComponent(component)
        }
    }

}