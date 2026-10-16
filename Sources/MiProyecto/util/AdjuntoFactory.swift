import Foundation
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

enum AdjuntoFactory {
    static let tamanoMaximoBytes = 15 * 1024 * 1024
    static let campoArchivos = "archivos[]"
    static let campoEvidencia = "evidencia"

    static func desdeURL(_ url: URL, fieldName: String = campoArchivos) throws -> UploadFile {
          if let values = try? url.resourceValues(forKeys: [.fileSizeKey]),
              let size = values.fileSize,
              size > tamanoMaximoBytes {
            throw AdjuntoError.fileTooLarge
        }
        #if os(iOS) || os(macOS)
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        #endif
        let data = try Data(contentsOf: url)
        guard data.count <= tamanoMaximoBytes else { throw AdjuntoError.fileTooLarge }
        let fileName = url.lastPathComponent
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")
        #if canImport(UniformTypeIdentifiers)
        let mimeType = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
        #else
        let mimeType = "application/octet-stream"
        #endif
        return UploadFile(
            fieldName: fieldName,
            fileName: fileName,
            mimeType: mimeType,
            data: data
        )
    }
}

enum AdjuntoError: LocalizedError {
    case fileTooLarge

    var errorDescription: String? {
        "El archivo supera el límite permitido de 15 MB."
    }
}