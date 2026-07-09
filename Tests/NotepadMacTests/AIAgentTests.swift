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

    func testProviderPresetsIncludeNoTokenLocalOllama() {
        let preset = AIAgentProviderPreset.localOllama

        XCTAssertEqual(preset.title, "Local Ollama")
        XCTAssertEqual(preset.configuration.endpointURL.absoluteString, "http://localhost:11434/v1/chat/completions")
        XCTAssertEqual(preset.configuration.modelName, "llama3.2")
        XCTAssertNil(preset.configuration.apiToken)
        XCTAssertFalse(preset.requiresToken)
    }

    func testProviderPresetsIncludeFreeTierRemoteOpenAICompatibleOptions() {
        let presets = AIAgentProviderPreset.remoteFreeTierPresets

        XCTAssertEqual(presets.map(\.title), ["OpenRouter Free Models", "Groq Free Tier", "Google Gemini Free Tier"])
        XCTAssertTrue(presets.allSatisfy(\.requiresToken))
        XCTAssertEqual(presets.map { $0.configuration.endpointURL.absoluteString }, [
            "https://openrouter.ai/api/v1/chat/completions",
            "https://api.groq.com/openai/v1/chat/completions",
            "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions"
        ])
        XCTAssertEqual(presets.first?.configuration.modelName, "cohere/north-mini-code:free")
    }

    func testClientReportsAgentErrorMessageFromOpenAICompatibleErrorObject() throws {
        let data = """
        {
          "error": {
            "message": "model 'missing-model' not found"
          }
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try client().decodeResponse(data: data, statusCode: 404)) { error in
            XCTAssertTrue(error.localizedDescription.contains("HTTP 404"))
            XCTAssertTrue(error.localizedDescription.contains("model 'missing-model' not found"))
        }
    }

    func testClientReportsAgentErrorMessageFromOllamaStringError() throws {
        let data = """
        {
          "error": "model is required"
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try client().decodeResponse(data: data, statusCode: 400)) { error in
            XCTAssertTrue(error.localizedDescription.contains("HTTP 400"))
            XCTAssertTrue(error.localizedDescription.contains("model is required"))
        }
    }

    func testClientReportsUnexpectedResponseInsteadOfDecoderMissingData() throws {
        let data = """
        {
          "done": true
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try client().decodeResponse(data: data, statusCode: 200)) { error in
            XCTAssertTrue(error.localizedDescription.contains("HTTP 200"))
            XCTAssertTrue(error.localizedDescription.contains("Unexpected AI agent response"))
            XCTAssertFalse(error.localizedDescription.contains("missing"))
        }
    }

    private func client() -> AIAgentClient {
        AIAgentClient(configuration: AIAgentConfiguration(
            endpointURL: URL(string: "http://localhost:11434/v1/chat/completions")!,
            modelName: "local-model",
            apiToken: nil,
            responseMode: .openAICompatibleJSON
        ))
    }
}
