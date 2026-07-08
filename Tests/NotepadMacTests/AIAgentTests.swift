import XCTest
@testable import NotepadMacCore

final class AIAgentTests: XCTestCase {
    func testSummarizerPromptUsesOnlySelectedText() {
        let task = AITextTask(
            id: "ai-summarizer",
            title: "AI Summarizer",
            menuTitle: "Summarize Selection",
            instruction: "Summarize the selected text.",
            resultDisposition: .replaceSelectionOrOpenDocument
        )

        let prompt = AITextPromptBuilder().prompt(
            for: task,
            selectedText: "Only this paragraph should be sent.",
            fileName: "notes.txt",
            languageName: "Plain Text"
        )

        XCTAssertTrue(prompt.contains("Only this paragraph should be sent."))
        XCTAssertTrue(prompt.contains("Summarize the selected text."))
        XCTAssertFalse(prompt.contains("whole document"))
    }

    func testCodeExplainerPromptIncludesFilenameLanguageAndSelectedCode() {
        let task = AITextTask(
            id: "ai-code-explainer",
            title: "AI Code Explainer",
            menuTitle: "Explain Code",
            instruction: "Explain the selected code.",
            resultDisposition: .openDocument
        )

        let prompt = AITextPromptBuilder().prompt(
            for: task,
            selectedText: "private float $dcaAmount;",
            fileName: "DCAAnalyzer.php",
            languageName: "PHP"
        )

        XCTAssertTrue(prompt.contains("DCAAnalyzer.php"))
        XCTAssertTrue(prompt.contains("PHP"))
        XCTAssertTrue(prompt.contains("private float $dcaAmount;"))
        XCTAssertTrue(prompt.contains("Explain the selected code."))
    }

    func testMeetingNotesPromptRequestsStructuredSections() {
        let prompt = AITextPromptBuilder().prompt(
            for: .meetingNotesCleaner,
            selectedText: "bob owns deploy, decision ship friday",
            fileName: "meeting.txt",
            languageName: "Plain Text"
        )

        XCTAssertTrue(prompt.contains("Summary"))
        XCTAssertTrue(prompt.contains("Decisions"))
        XCTAssertTrue(prompt.contains("Action items"))
        XCTAssertTrue(prompt.contains("Open questions"))
    }

    func testSmartSearchPromptIncludesQueryAndOpenDocumentSnippets() {
        let prompt = AITextPromptBuilder().smartSearchPrompt(
            query: "deployment plan",
            documents: [
                AISearchDocument(id: "1", title: "Release Notes", snippet: "Deploy on Friday."),
                AISearchDocument(id: "2", title: "Ideas", snippet: "Later product ideas.")
            ]
        )

        XCTAssertTrue(prompt.contains("deployment plan"))
        XCTAssertTrue(prompt.contains("Release Notes"))
        XCTAssertTrue(prompt.contains("Deploy on Friday."))
        XCTAssertTrue(prompt.contains("Return matching document ids"))
    }

    func testOpenAICompatibleRequestDoesNotRequireBuiltInCredentials() throws {
        let configuration = AIAgentConfiguration(
            endpointURL: URL(string: "http://localhost:11434/v1/chat/completions")!,
            modelName: "local-model",
            apiToken: nil,
            responseMode: .openAICompatibleJSON
        )

        let request = try AIAgentClient(configuration: configuration).makeURLRequest(prompt: "Summarize this.")

        XCTAssertEqual(request.url, configuration.endpointURL)
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }
}
