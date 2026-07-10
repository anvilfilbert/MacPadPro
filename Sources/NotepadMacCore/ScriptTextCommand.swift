import Foundation
import JavaScriptCore

public enum ScriptTextCommandError: LocalizedError, Equatable {
    case couldNotCreateContext
    case scriptCouldNotDecode(path: String)
    case missingTransformFunction(path: String)
    case scriptException(message: String)
    case transformReturnedNoText(commandID: String)

    public var errorDescription: String? {
        switch self {
        case .couldNotCreateContext:
            "Could not create JavaScript execution context."
        case let .scriptCouldNotDecode(path):
            "Could not decode plugin script as UTF-8: \(path)."
        case let .missingTransformFunction(path):
            "Plugin script must define function transform(input): \(path)."
        case let .scriptException(message):
            "Plugin script failed: \(message)."
        case let .transformReturnedNoText(commandID):
            "Plugin command '\(commandID)' did not return text."
        }
    }
}

public struct ScriptTextCommand: Sendable, Equatable {
    public let id: String
    public let title: String
    public let scriptURL: URL

    public init(id: String, title: String, scriptURL: URL) {
        self.id = id
        self.title = title
        self.scriptURL = scriptURL
    }

    public func transform(_ text: String) throws -> String {
        let scriptData = try Data(contentsOf: scriptURL)
        guard let script = String(data: scriptData, encoding: .utf8) else {
            throw ScriptTextCommandError.scriptCouldNotDecode(path: scriptURL.path)
        }
        guard let context = JSContext() else {
            throw ScriptTextCommandError.couldNotCreateContext
        }

        var exceptionMessage: String?
        context.exceptionHandler = { _, exception in
            exceptionMessage = exception?.toString() ?? "Unknown JavaScript error"
        }
        context.evaluateScript(script)
        if let exceptionMessage {
            throw ScriptTextCommandError.scriptException(message: exceptionMessage)
        }

        let transformFunction = context.objectForKeyedSubscript("transform")
        guard let transformFunction, !transformFunction.isUndefined else {
            throw ScriptTextCommandError.missingTransformFunction(path: scriptURL.path)
        }

        let result = transformFunction.call(withArguments: [text])
        if let exceptionMessage {
            throw ScriptTextCommandError.scriptException(message: exceptionMessage)
        }
        guard let output = result?.toString() else {
            throw ScriptTextCommandError.transformReturnedNoText(commandID: id)
        }
        return output
    }

    public var textCommand: TextCommand {
        TextCommand(id: id, title: title) { text in
            try transform(text)
        }
    }
}
