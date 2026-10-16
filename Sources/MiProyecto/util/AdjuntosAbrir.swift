#if canImport(SwiftUI)
import AVFoundation
import Combine
import SwiftUI

@MainActor
private final class AudioAdjuntoPlayer: ObservableObject {
    @Published private(set) var isPlaying = false
    private(set) var player: AVPlayer?

    func toggle(url: URL? = nil) {
        if isPlaying {
            player?.pause()
            isPlaying = false
        } else {
            if player == nil, let url { player = AVPlayer(url: url) }
            guard player != nil else { return }
            player?.play()
            isPlaying = true
        }
    }

    func finish(_ item: AVPlayerItem?) {
        guard item != nil, item === player?.currentItem else { return }
        isPlaying = false
        player?.seek(to: .zero)
    }
}

private struct AttachmentPreview: Identifiable {
    let id = UUID()
    let url: URL
}

struct AdjuntosAbrir: View {
    let attachment: AttachmentDto
    @Environment(\.openURL) private var openURL
    @StateObject private var audioPlayer = AudioAdjuntoPlayer()
    @State private var isResolving = false
    @State private var errorMessage: String?
    @State private var preview: AttachmentPreview?

    private var isAudio: Bool {
        let name = attachment.nombreOriginal.lowercased()
        let url = attachment.url.lowercased()
        return [".m4a", ".mp3", ".wav", ".aac", ".mp4", ".caf"].contains { name.hasSuffix($0) }
            || url.contains("audio")
    }

    var body: some View {
        HStack(spacing: 8) {
            Button {
                Task { await activateAttachment() }
            } label: {
                Label(buttonTitle, systemImage: buttonIcon)
                    .lineLimit(1)
            }
            .disabled(isResolving)
            if isResolving { ProgressView().controlSize(.small) }
            if let errorMessage {
                Text(errorMessage).font(.caption2).foregroundStyle(.red).lineLimit(2)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { notification in
            audioPlayer.finish(notification.object as? AVPlayerItem)
        }
        .sheet(item: $preview) { item in ImageViewerDialog(url: item.url) }
    }

    private var buttonTitle: String {
        if isAudio { return "\(audioPlayer.isPlaying ? "Pausar" : "Reproducir") · \(attachment.nombreOriginal)" }
        return attachment.nombreOriginal
    }

    private var buttonIcon: String {
        if isAudio { return audioPlayer.isPlaying ? "pause.fill" : "play.fill" }
        return attachment.esImagen ? "photo" : "paperclip"
    }

    @MainActor
    private func activateAttachment() async {
        guard !isResolving else { return }
        if isAudio, audioPlayer.player != nil {
            audioPlayer.toggle()
            return
        }
        isResolving = true
        errorMessage = nil
        defer { isResolving = false }
        do {
            let response = try await ApiService.shared.enlaceAdjunto(id: attachment.id)
            guard response.ok, let value = response.url,
                  let url = try? UrlSegura.validar(value) else {
                errorMessage = response.error ?? "No se pudo abrir el archivo."
                return
            }
            if isAudio {
                audioPlayer.toggle(url: url)
            } else if attachment.esImagen {
                preview = AttachmentPreview(url: url)
            } else {
                openURL(url)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
#endif