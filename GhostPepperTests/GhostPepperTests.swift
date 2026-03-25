import XCTest
import LLM
@testable import GhostPepper

final class GhostPepperTests: XCTestCase {
    override func tearDown() {
        PermissionChecker.current = PermissionChecker.defaultClient
        super.tearDown()
    }

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

    func testCheckMicrophoneUsesInjectedClientWithoutSystemPrompt() async {
        var requestCount = 0
        PermissionChecker.current = PermissionChecker.Client(
            checkAccessibility: { false },
            promptAccessibility: {},
            microphoneStatus: { .notDetermined },
            requestMicrophoneAccess: {
                requestCount += 1
                return true
            },
            openAccessibilitySettings: {},
            openMicrophoneSettings: {}
        )

        let granted = await PermissionChecker.checkMicrophone()

        XCTAssertTrue(granted)
        XCTAssertEqual(requestCount, 1)
    }

    func testDefaultClientIsNonInteractiveDuringTests() async {
        PermissionChecker.current = PermissionChecker.defaultClient

        let granted = await PermissionChecker.checkMicrophone()

        XCTAssertFalse(granted)
        XCTAssertEqual(PermissionChecker.microphoneStatus(), .denied)
    }
}
