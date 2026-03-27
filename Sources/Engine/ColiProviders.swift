import Foundation

/// ASR provider that uses the coli CLI with the SenseVoice model (default).
/// Supports Chinese, English, Japanese, Korean, and Cantonese.
struct ColiSenseVoiceProvider: ASRProvider {
    let id = "coli-sensevoice"
    let displayName = "SenseVoice"
    let subtitle = "Offline · zh/en/ja/ko/yue"

    private let transcriber = ColiTranscriber()

    func isAvailable() -> Bool {
        ColiTranscriber.isAvailable(at: AppPaths.coliHelperPath)
    }

    func transcribe(filePath: String) async throws -> TranscriptionResult {
        try await transcriber.transcribe(
            filePath: filePath,
            coliPath: AppPaths.coliHelperPath,
            model: "sensevoice"
        )
    }
}

/// ASR provider that uses the coli CLI with the Whisper tiny.en model.
/// English only, lightweight and fast.
struct ColiWhisperProvider: ASRProvider {
    let id = "coli-whisper"
    let displayName = "Whisper"
    let subtitle = "Offline · English only"

    private let transcriber = ColiTranscriber()

    func isAvailable() -> Bool {
        ColiTranscriber.isAvailable(at: AppPaths.coliHelperPath)
    }

    func transcribe(filePath: String) async throws -> TranscriptionResult {
        try await transcriber.transcribe(
            filePath: filePath,
            coliPath: AppPaths.coliHelperPath,
            model: "whisper"
        )
    }
}
