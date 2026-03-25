import XCTest
import LLM
@testable import GhostPepper

final class GhostPepperTests: XCTestCase {
    func testAppStateInitialStatus() {
        // AppState is @MainActor so we test basic enum
        XCTAssertEqual(AppStatus.ready.rawValue, "Ready")
        XCTAssertEqual(AppStatus.recording.rawValue, "Recording...")
        XCTAssertEqual(AppStatus.transcribing.rawValue, "Transcribing...")
        XCTAssertEqual(AppStatus.error.rawValue, "Error")
    }

    func testCleanupTemplateUsesQwenThinkingFormat() {
        let prompt = "You are helpful."
        let template = HuggingFaceModel("unsloth/Qwen3.5-4B-GGUF").resolveTemplate(systemPrompt: prompt)
        let output = template.preprocess("Hello", [], .suppressed)
        let expected = """
        <|im_start|>system
        \(prompt)<|im_end|>
        <|im_start|>user
        Hello<|im_end|>
        <|im_start|>assistant
        <think>

        </think>

        """ + "\n"
        XCTAssertEqual(output, expected)
    }
}
