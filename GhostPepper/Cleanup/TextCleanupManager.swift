import Foundation
import LLM

enum CleanupModelState: Equatable {
    case idle
    case downloading(progress: Double)
    case loadingModel
    case ready
    case error
}

@MainActor
final class TextCleanupManager: ObservableObject {
    @Published private(set) var state: CleanupModelState = .idle
    @Published private(set) var errorMessage: String?

    /// Fast model for short inputs (< 15 words)
    private(set) var fastLLM: LLM?
    /// Full model for longer inputs
    private(set) var fullLLM: LLM?

    private static let fastModelFileName = "Qwen3-1.7B.Q4_K_M.gguf"
    private static let fastModelURL = "https://huggingface.co/MaziyarPanahi/Qwen3-1.7B-GGUF/resolve/main/Qwen3-1.7B.Q4_K_M.gguf"

    private static let fullModelFileName = "Qwen3.5-4B-Q4_K_M.gguf"
    private static let fullModelURL = "https://huggingface.co/unsloth/Qwen3.5-4B-GGUF/resolve/main/Qwen3.5-4B-Q4_K_M.gguf"

    static let shortInputThreshold = 15

    var isReady: Bool { state == .ready }

    /// Returns the appropriate model based on word count.
    func model(for wordCount: Int) -> LLM? {
        if wordCount <= Self.shortInputThreshold {
            return fastLLM ?? fullLLM
        }
        return fullLLM
    }

    var statusText: String {
        switch state {
        case .idle:
            return ""
        case .downloading(let progress):
            let pct = Int(progress * 100)
            return "Downloading cleanup models (\(pct)%)..."
        case .loadingModel:
            return "Loading cleanup models..."
        case .ready:
            return ""
        case .error:
            return errorMessage ?? "Cleanup model error"
        }
    }

    private var modelsDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("GhostPepper/models", isDirectory: true)
    }

    private func modelPath(for fileName: String) -> URL {
        modelsDirectory.appendingPathComponent(fileName)
    }

    func loadModel() async {
        guard state == .idle || state == .error else { return }

        errorMessage = nil
        try? FileManager.default.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)

        // Download both models if needed
        let fastPath = modelPath(for: Self.fastModelFileName)
        let fullPath = modelPath(for: Self.fullModelFileName)

        let needsFast = !FileManager.default.fileExists(atPath: fastPath.path)
        let needsFull = !FileManager.default.fileExists(atPath: fullPath.path)

        if needsFast || needsFull {
            state = .downloading(progress: 0)
            do {
                if needsFast {
                    try await downloadModel(url: Self.fastModelURL, to: fastPath, progressOffset: 0, progressScale: needsFull ? 0.33 : 1.0)
                }
                if needsFull {
                    try await downloadModel(url: Self.fullModelURL, to: fullPath, progressOffset: needsFast ? 0.33 : 0, progressScale: needsFast ? 0.67 : 1.0)
                }
            } catch {
                self.errorMessage = "Failed to download cleanup model: \(error.localizedDescription)"
                self.state = .error
                return
            }
        }

        state = .loadingModel

        // Load fast model first (smaller, quicker to load)
        let fast = await Task.detached { () -> LLM? in
            guard let llm = LLM(from: fastPath, maxTokenCount: 2048) else { return nil }
            llm.useResolvedTemplate(systemPrompt: TextCleaner.defaultPrompt)
            return llm
        }.value

        if let fast = fast {
            fast.temp = 0.1
            fast.update = { (_: String?) in }
            fast.postprocess = { (_: String) in }
            self.fastLLM = fast
        }

        // Load full model
        let full = await Task.detached { () -> LLM? in
            guard let llm = LLM(from: fullPath, maxTokenCount: 4096) else { return nil }
            llm.useResolvedTemplate(systemPrompt: TextCleaner.defaultPrompt)
            return llm
        }.value

        guard let full = full else {
            self.errorMessage = "Failed to load cleanup model"
            self.state = .error
            return
        }

        full.temp = 0.1
        full.update = { (_: String?) in }
        full.postprocess = { (_: String) in }
        self.fullLLM = full
        self.state = .ready
    }

    func unloadModel() {
        fastLLM = nil
        fullLLM = nil
        state = .idle
        errorMessage = nil
    }

    private func downloadModel(url urlString: String, to destination: URL, progressOffset: Double, progressScale: Double) async throws {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let delegate = DownloadProgressDelegate { [weak self] progress in
            Task { @MainActor in
                self?.state = .downloading(progress: progressOffset + progress * progressScale)
            }
        }

        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        let (tempURL, _) = try await session.download(from: url)
        try FileManager.default.moveItem(at: tempURL, to: destination)
    }
}

// MARK: - Download Progress

private final class DownloadProgressDelegate: NSObject, URLSessionDownloadDelegate {
    let onProgress: @Sendable (Double) -> Void

    init(onProgress: @escaping @Sendable (Double) -> Void) {
        self.onProgress = onProgress
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        onProgress(progress)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Handled by the async download(from:) call
    }
}
