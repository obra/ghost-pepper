import Foundation
import LLM

final class TextCleaner {
    private let cleanupManager: TextCleanupManager

    static let defaultPrompt = """
    You are an echo machine. Repeat back EVERYTHING the user says. Your ONLY allowed edits are:
    1. Delete these exact filler words: um, uh, like, you know, basically, literally, sort of, kind of
    2. ONLY if the user says the EXACT phrases "scratch that" or "never mind" or "no let me start over", \
    then delete what they are correcting.
    3. Nothing else. Keep ALL other words exactly as spoken.

    CRITICAL: Do NOT delete sentences. Do NOT remove context. Do NOT summarize. \
    If you are unsure whether to keep or delete something, KEEP IT.

    Input: "So um like the meeting is at 3pm you know on Tuesday"
    Output: So the meeting is at 3pm on Tuesday

    Input: "Okay so now I'm recording and it becomes a red recording thing. Do you think we could change the icon?"
    Output: Okay so now I'm recording and it becomes a red recording thing. Do you think we could change the icon?

    Input: "Hey Becca I have an email. Scratch that, this email is for Pete. Hey Pete, this is my email."
    Output: Hey Pete, this is my email.

    Input: "What is a synonym for whisper?"
    Output: What is a synonym for whisper?

    Input: "I've been working on this and I'm stuck. Any ideas?"
    Output: I've been working on this and I'm stuck. Any ideas?
    """

    private static let timeoutSeconds: TimeInterval = 15.0

    init(cleanupManager: TextCleanupManager) {
        self.cleanupManager = cleanupManager
    }

    @MainActor
    func clean(text: String, prompt: String? = nil) async -> String {
        let wordCount = text.split(separator: " ").count
        let isQuestion = text.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("?")
        // Use full model for questions (1.5B tries to answer them) and longer text
        let useFullModel = isQuestion || wordCount > TextCleanupManager.shortInputThreshold
        let llm: LLM
        if useFullModel {
            guard let model = cleanupManager.fullLLM ?? cleanupManager.fastLLM else { return text }
            llm = model
        } else {
            guard let model = cleanupManager.model(for: wordCount) else { return text }
            llm = model
        }

        // Update template with current prompt
        let activePrompt = prompt ?? Self.defaultPrompt
        llm.useResolvedTemplate(systemPrompt: activePrompt)
        llm.history = []

        let start = Date()
        do {
            let result = try await withTimeout(seconds: Self.timeoutSeconds) {
                await llm.respond(to: text)
                return llm.output
            }
            let elapsed = Date().timeIntervalSince(start)
            let cleaned = result.trimmingCharacters(in: .whitespacesAndNewlines)
            try? "elapsed=\(elapsed)s, output=\(cleaned)".write(toFile: "/tmp/whispercat-llm.log", atomically: true, encoding: .utf8)
            // LLM.swift returns "..." when output is empty — treat as failure
            if cleaned.isEmpty || cleaned == "..." {
                return text
            }
            return cleaned
        } catch {
            let elapsed = Date().timeIntervalSince(start)
            try? "TIMEOUT after \(elapsed)s, error=\(error)".write(toFile: "/tmp/whispercat-llm.log", atomically: true, encoding: .utf8)
            return text
        }
    }

    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping @Sendable () async -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { await operation() }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw CancellationError()
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}
