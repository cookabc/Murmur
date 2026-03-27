import Foundation

/// A speech-to-text backend that can transcribe an audio file.
protocol ASRProvider: Sendable {
    /// Unique identifier used for persistence (e.g. "coli-sensevoice").
    var id: String { get }
    /// Human-readable name shown in the UI.
    var displayName: String { get }
    /// Short description of the provider's capabilities.
    var subtitle: String { get }
    /// Whether this provider is available on the current system.
    func isAvailable() -> Bool
    /// Transcribe the audio file at `filePath`.
    func transcribe(filePath: String) async throws -> TranscriptionResult
}

// MARK: - Registry

/// Manages the set of available ASR providers and the user's active selection.
@MainActor
final class ASRProviderRegistry: ObservableObject {
    static let shared = ASRProviderRegistry()

    private static let selectedProviderUD = "asr_selected_provider"

    @Published private(set) var providers: [any ASRProvider] = []
    @Published var selectedID: String {
        didSet { UserDefaults.standard.set(selectedID, forKey: Self.selectedProviderUD) }
    }

    var activeProvider: (any ASRProvider)? {
        providers.first(where: { $0.id == selectedID }) ?? providers.first
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: Self.selectedProviderUD)

        // Register built-in providers.
        let builtIn: [any ASRProvider] = [
            ColiSenseVoiceProvider(),
            ColiWhisperProvider(),
        ]
        self.providers = builtIn
        self.selectedID = saved ?? builtIn.first?.id ?? ""
    }

    func register(_ provider: any ASRProvider) {
        guard !providers.contains(where: { $0.id == provider.id }) else { return }
        providers.append(provider)
    }
}
