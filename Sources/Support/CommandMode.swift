import Foundation

/// A post-transcription command that overrides the default LLM polish prompt.
struct CommandTemplate: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: String
    let systemPrompt: String
    /// If non-empty, wraps the transcript with this template using `{text}`.
    let userTemplate: String

    static func == (lhs: CommandTemplate, rhs: CommandTemplate) -> Bool {
        lhs.id == rhs.id
    }
}

/// Manages the set of available command-mode templates.
@MainActor
final class CommandModeManager: ObservableObject {
    static let shared = CommandModeManager()

    /// nil = default polish mode (clean transcript).
    @Published var activeCommand: CommandTemplate?

    let builtInCommands: [CommandTemplate] = [
        CommandTemplate(
            id: "translate-en",
            name: "Translate → EN",
            icon: "globe",
            systemPrompt: """
                You are a translator. Translate the provided text into English.
                Rules:
                (1) Output only the translated text and nothing else.
                (2) Preserve the original meaning, tone, and formatting.
                (3) Do NOT add explanations, notes, or comments.
                """,
            userTemplate: "{text}"
        ),
        CommandTemplate(
            id: "summarize",
            name: "Summarize",
            icon: "text.redaction",
            systemPrompt: """
                You are a summarizer. Condense the provided text into a concise summary.
                Rules:
                (1) Output only the summary and nothing else.
                (2) Keep the summary to 1-3 sentences.
                (3) Preserve the key points and original language.
                (4) Do NOT add your own opinions or comments.
                """,
            userTemplate: "{text}"
        ),
        CommandTemplate(
            id: "email-reply",
            name: "Email Reply",
            icon: "envelope",
            systemPrompt: """
                You are an email assistant. The user has dictated a rough reply. Polish it into a professional email reply.
                Rules:
                (1) Output only the polished email text and nothing else.
                (2) Maintain the user's intent and key points.
                (3) Use professional but natural tone.
                (4) Add a greeting and sign-off if missing. Use "Best regards" as default.
                (5) Preserve the original language — do not translate.
                """,
            userTemplate: "{text}"
        ),
    ]

    func selectCommand(_ command: CommandTemplate?) {
        activeCommand = command
    }

    func clearCommand() {
        activeCommand = nil
    }
}
