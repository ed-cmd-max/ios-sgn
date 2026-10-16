#if os(iOS) && canImport(AVFoundation) && canImport(Combine)
import AVFoundation
import Combine
import Foundation

@MainActor
final class VoiceNoteRecorder: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var elapsedSeconds = 0
    @Published private(set) var errorMessage: String?

    private var recorder: AVAudioRecorder?
    private var timerTask: Task<Void, Never>?
    private var recordingURL: URL?

    func start() async -> Bool {
        errorMessage = nil
        guard await AVAudioApplication.requestRecordPermission() else {
            errorMessage = "Permite el acceso al micrófono para grabar una nota de voz."
            return false
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try session.setActive(true)

            let directory = FileManager.default.temporaryDirectory.appendingPathComponent("sgn-chat-audio", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let url = directory.appendingPathComponent("VOICE_\(UUID().uuidString).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderBitRateKey: 96_000
            ]
            let audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder.prepareToRecord()
            guard audioRecorder.record() else {
                throw VoiceRecordingError.couldNotStart
            }

            recorder = audioRecorder
            recordingURL = url
            elapsedSeconds = 0
            isRecording = true
            timerTask = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(1))
                    guard !Task.isCancelled, isRecording else { break }
                    elapsedSeconds += 1
                }
            }
            return true
        } catch {
            errorMessage = "No se pudo iniciar la grabación de audio."
            await releaseAudioSession()
            return false
        }
    }

    func finish() -> URL? {
        guard isRecording, let recordingURL else { return nil }
        stopRecorder()
        guard let size = try? recordingURL.resourceValues(forKeys: [.fileSizeKey]).fileSize,
              size > 100 else {
            try? FileManager.default.removeItem(at: recordingURL)
            errorMessage = "La nota de voz es demasiado corta o está vacía."
            return nil
        }
        return recordingURL
    }

    func cancel() {
        let url = recordingURL
        stopRecorder()
        if let url { try? FileManager.default.removeItem(at: url) }
    }

    private func stopRecorder() {
        timerTask?.cancel()
        timerTask = nil
        recorder?.stop()
        recorder = nil
        recordingURL = nil
        isRecording = false
        Task { await releaseAudioSession() }
    }

    private func releaseAudioSession() async {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

private enum VoiceRecordingError: Error {
    case couldNotStart
}
#endif
