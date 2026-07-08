import Foundation

public enum AIAgentResponseMode: String, Codable, Sendable, Equatable, CaseIterable {
    case openAICompatibleJSON
}

public struct AIAgentConfiguration: Codable, Sendable, Equatable {
    public let endpointURL: URL
    public let modelName: String
    public let apiToken: String?
    public let responseMode: AIAgentResponseMode

    public init(endpointURL: URL, modelName: String, apiToken: String?, responseMode: AIAgentResponseMode) {
        self.endpointURL = endpointURL
        self.modelName = modelName
        self.apiToken = apiToken
        self.responseMode = responseMode
    }
}

public enum AITextResultDisposition: String, Codable, Sendable, Equatable {
    case openDocument
    case previewDocument
    case replaceSelectionOrOpenDocument
}

public struct AITextTask: Sendable, Equatable {
    public let id: String
    public let title: String
    public let menuTitle: String
    public let instruction: String
    public let resultDisposition: AITextResultDisposition

    public init(id: String, title: String, menuTitle: String, instruction: String, resultDisposition: AITextResultDisposition) {
        self.id = id
        self.title = title
        self.menuTitle = menuTitle
        self.instruction = instruction
        self.resultDisposition = resultDisposition
    }
}

public extension AITextTask {
    static let summarizer = AITextTask(
        id: "ai-summarizer",
        title: "AI Summarizer",
        menuTitle: "Summarize Selection",
        instruction: "Summarize the selected text clearly and concisely. Focus on the important facts, risks, and next steps.",
        resultDisposition: .replaceSelectionOrOpenDocument
    )

    static let codeExplainer = AITextTask(
        id: "ai-code-explainer",
        title: "AI Code Explainer",
        menuTitle: "Explain Code",
        instruction: "Explain the selected code. Include purpose, important control flow, data structures, and any notable risks.",
        resultDisposition: .openDocument
    )

    static let codeRefactor = AITextTask(
        id: "ai-code-refactor",
        title: "AI Code Refactor Assistant",
        menuTitle: "Suggest Refactor",
        instruction: "Suggest a refactor for the selected code. Return improved code first, then short notes explaining the changes.",
        resultDisposition: .previewDocument
    )

    static let meetingNotesCleaner = AITextTask(
        id: "ai-meeting-notes",
        title: "AI Meeting Notes Cleaner",
        menuTitle: "Clean Meeting Notes",
        instruction: """
        Clean the selected meeting notes into these sections:
        Summary
        Decisions
        Action items
        Open questions
        """,
        resultDisposition: .replaceSelectionOrOpenDocument
    )
}

public struct AISmartSearchExtension: Sendable, Equatable {
    public let id: String
    public let title: String

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

public struct AISearchDocument: Sendable, Equatable {
    public let id: String
    public let title: String
    public let snippet: String

    public init(id: String, title: String, snippet: String) {
        self.id = id
        self.title = title
        self.snippet = snippet
    }
}

public struct AISearchResult: Sendable, Equatable {
    public let documentID: String
    public let title: String
    public let reason: String

    public init(documentID: String, title: String, reason: String) {
        self.documentID = documentID
        self.title = title
        self.reason = reason
    }
}

public struct AITextResult: Sendable, Equatable {
    public let text: String

    public init(text: String) {
        self.text = text
    }
}

public enum AIAgentClientError: LocalizedError, Equatable {
    case agentError(statusCode: Int, message: String)
    case unexpectedResponse(statusCode: Int, body: String)

    public var errorDescription: String? {
        switch self {
        case let .agentError(statusCode, message):
            "AI agent returned HTTP \(statusCode) with error: \(message)"
        case let .unexpectedResponse(statusCode, body):
            "Unexpected AI agent response from HTTP \(statusCode). \(body)"
        }
    }
}

public struct AITextPromptBuilder: Sendable {
    public init() {}

    public func prompt(for task: AITextTask, selectedText: String, fileName: String, languageName: String) -> String {
        """
        You are helping inside MacPad Pro.

        Task:
        \(task.instruction)

        Context:
        File name: \(fileName)
        Detected language: \(languageName)

        Selected text:
        \(selectedText)
        """
    }

    public func smartSearchPrompt(query: String, documents: [AISearchDocument]) -> String {
        let snippets = documents.map { document in
            """
            Document id: \(document.id)
            Title: \(document.title)
            Snippet:
            \(document.snippet)
            """
        }.joined(separator: "\n\n---\n\n")

        return """
        You are helping MacPad Pro search currently open documents.

        Query:
        \(query)

        Open document snippets:
        \(snippets)

        Return matching document ids with a short reason for each match.
        Use one line per result in this format:
        document-id | reason
        """
    }
}

public struct AIAgentClient: Sendable {
    public let configuration: AIAgentConfiguration

    public init(configuration: AIAgentConfiguration) {
        self.configuration = configuration
    }

    public func makeURLRequest(prompt: String) throws -> URLRequest {
        var request = URLRequest(url: configuration.endpointURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiToken = configuration.apiToken, !apiToken.isEmpty {
            request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        }

        let body = OpenAICompatibleChatRequest(
            model: configuration.modelName,
            messages: [OpenAICompatibleMessage(role: "user", content: prompt)]
        )
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    public func complete(prompt: String) async throws -> AITextResult {
        let request = try makeURLRequest(prompt: prompt)
        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 200
        return try decodeResponse(data: data, statusCode: statusCode)
    }

    public func decodeResponse(data: Data, statusCode: Int) throws -> AITextResult {
        if let errorMessage = decodeAgentErrorMessage(from: data) {
            throw AIAgentClientError.agentError(statusCode: statusCode, message: errorMessage)
        }

        guard (200..<300).contains(statusCode) else {
            throw AIAgentClientError.unexpectedResponse(statusCode: statusCode, body: responsePreview(from: data))
        }

        guard let response = try? JSONDecoder().decode(OpenAICompatibleChatResponse.self, from: data),
              let content = response.choices.first?.message.content else {
            throw AIAgentClientError.unexpectedResponse(statusCode: statusCode, body: responsePreview(from: data))
        }

        return AITextResult(text: content)
    }

    private func decodeAgentErrorMessage(from data: Data) -> String? {
        if let objectError = try? JSONDecoder().decode(OpenAICompatibleErrorResponse.self, from: data) {
            return objectError.error.message
        }
        if let stringError = try? JSONDecoder().decode(OllamaStringErrorResponse.self, from: data) {
            return stringError.error
        }
        return nil
    }

    private func responsePreview(from data: Data) -> String {
        let body = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? "<non-text response>"
        guard !body.isEmpty else { return "<empty response>" }
        return String(body.prefix(500))
    }
}

private struct OpenAICompatibleChatRequest: Codable {
    let model: String
    let messages: [OpenAICompatibleMessage]
}

private struct OpenAICompatibleMessage: Codable {
    let role: String
    let content: String
}

private struct OpenAICompatibleChatResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: OpenAICompatibleMessage
    }
}

private struct OpenAICompatibleErrorResponse: Codable {
    let error: ErrorDetail

    struct ErrorDetail: Codable {
        let message: String
    }
}

private struct OllamaStringErrorResponse: Codable {
    let error: String
}
