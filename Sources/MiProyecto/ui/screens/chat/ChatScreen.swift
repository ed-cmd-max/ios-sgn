#if canImport(SwiftUI)
import SwiftUI
import UniformTypeIdentifiers

struct ChatScreen: View {
    let ticketId: Int
    let ticketCode: String
    let user: UserDto
    @StateObject private var viewModel = ChatViewModel()
    @StateObject private var voiceRecorder = VoiceNoteRecorder()
    @State private var files: [UploadFile] = []
    @State private var showingFilePicker = false
    @State private var isInternalNote = false

    var body: some View {
        VStack(spacing: 0) {
            if let error = viewModel.errorMessage {
                Text(error).font(.footnote).foregroundStyle(.red).padding(.horizontal)
            }
            if viewModel.isLoading {
                ProgressView().frame(maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(message.autorNombre ?? message.usuario?.nombreMostrable ?? "Usuario")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    if let text = message.mensaje, !text.isEmpty { Text(text) }
                                    ForEach(message.adjuntos) { file in AdjuntosAbrir(attachment: file).font(.footnote) }
                                    if let date = message.fecha { Text(date).font(.caption2).foregroundStyle(.tertiary) }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(message.esNotaInterna ? Color.orange.opacity(0.12) : Color.blue.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        if let last = viewModel.messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
            if voiceRecorder.isRecording {
                HStack(spacing: 14) {
                    Button("Cancelar grabación", systemImage: "xmark.circle.fill", role: .destructive) {
                        voiceRecorder.cancel()
                    }
                    .labelStyle(.iconOnly)
                    .accessibilityLabel("Cancelar grabación")

                    Label("Grabando \(formattedDuration(voiceRecorder.elapsedSeconds))", systemImage: "record.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)

                    Button("Terminar y enviar", systemImage: "checkmark.circle.fill") {
                        Task { await sendVoiceNote() }
                    }
                    .labelStyle(.iconOnly)
                    .font(.title2)
                    .foregroundStyle(.green)
                    .accessibilityLabel("Terminar y enviar nota de voz")
                }
                .padding()
            } else {
                HStack(alignment: .bottom, spacing: 10) {
                    Button("Adjuntar", systemImage: "paperclip") { showingFilePicker = true }
                        .labelStyle(.iconOnly)
                        .accessibilityLabel("Adjuntar archivos")
                    TextField("Escribe un mensaje", text: $viewModel.text, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)
                    if viewModel.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && files.isEmpty {
                        Button {
                            Task { _ = await voiceRecorder.start() }
                        } label: {
                            Image(systemName: "mic.fill")
                                .frame(width: 40, height: 40)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Grabar nota de voz")
                    } else {
                        Button {
                            Task {
                                if await viewModel.send(ticketId: ticketId, files: files, isInternal: isInternalNote) {
                                    files = []
                                    isInternalNote = false
                                }
                            }
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .frame(width: 40, height: 40)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isSending)
                    }
                }
                .padding()
            }
            if let error = voiceRecorder.errorMessage {
                Text(error).font(.footnote).foregroundStyle(.red).padding(.horizontal)
            }
            if user.puedeAtenderTickets {
                Toggle("Nota interna", isOn: $isInternalNote)
                    .font(.caption)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
        .navigationTitle(ticketCode)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load(ticketId: ticketId)
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 3_500_000_000)
                guard !Task.isCancelled else { break }
                await viewModel.poll(ticketId: ticketId)
            }
        }
        .fileImporter(isPresented: $showingFilePicker, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
            guard case .success(let urls) = result else { return }
            for url in urls {
                do { files.append(try AdjuntoFactory.desdeURL(url)) }
                catch { viewModel.setError(error.localizedDescription) }
            }
        }
    }

    private func sendVoiceNote() async {
        guard let url = voiceRecorder.finish() else { return }
        do {
            let upload = try AdjuntoFactory.desdeURL(url)
            if await viewModel.send(ticketId: ticketId, files: [upload], isInternal: isInternalNote) {
                isInternalNote = false
                try? FileManager.default.removeItem(at: url)
            }
        } catch {
            viewModel.setError(error.localizedDescription)
        }
    }

    private func formattedDuration(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
#endif