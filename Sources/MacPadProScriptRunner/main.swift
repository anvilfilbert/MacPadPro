import Foundation
import JavaScriptCore

private enum ScriptRunnerError: LocalizedError {
    case invalidArguments
    case scriptCouldNotDecode(path: String)
    case couldNotCreateContext
    case missingTransformFunction(path: String)
    case scriptException(message: String)
    case transformReturnedNoText(commandID: String)
    case outputTooLarge(commandID: String, maxBytes: Int)

    var errorDescription: String? {
        switch self {
        case .invalidArguments:
            "Usage: MacPadProScriptRunner <command-id> <script-path>."
        case let .scriptCouldNotDecode(path):
            "Could not decode plugin script as UTF-8: \(path)."
        case .couldNotCreateContext:
            "Could not create JavaScript execution context."
        case let .missingTransformFunction(path):
            "Plugin script must define function transform(input): \(path)."
        case let .scriptException(message):
            "Plugin script failed: \(message)."
        case let .transformReturnedNoText(commandID):
            "Plugin command '\(commandID)' did not return text."
        case let .outputTooLarge(commandID, maxBytes):
            "Plugin command '\(commandID)' returned more than \(maxBytes) bytes."
        }
    }
}

private let maximumOutputBytes = 512 * 1024

private func run() throws {
    guard CommandLine.arguments.count == 3 else {
        throw ScriptRunnerError.invalidArguments
    }
    let commandID = CommandLine.arguments[1]
    let scriptPath = CommandLine.arguments[2]
    let scriptURL = URL(fileURLWithPath: scriptPath)
    let inputData = FileHandle.standardInput.readDataToEndOfFile()
    let input = String(data: inputData, encoding: .utf8) ?? ""
    let scriptData = try Data(contentsOf: scriptURL)
    guard let script = String(data: scriptData, encoding: .utf8) else {
        throw ScriptRunnerError.scriptCouldNotDecode(path: scriptPath)
    }
    guard let context = JSContext() else {
        throw ScriptRunnerError.couldNotCreateContext
    }

    var exceptionMessage: String?
    context.exceptionHandler = { _, exception in
        exceptionMessage = exception?.toString() ?? "Unknown JavaScript error"
    }
    context.evaluateScript(script)
    if let exceptionMessage {
        throw ScriptRunnerError.scriptException(message: exceptionMessage)
    }

    let transformFunction = context.objectForKeyedSubscript("transform")
    guard let transformFunction, !transformFunction.isUndefined else {
        throw ScriptRunnerError.missingTransformFunction(path: scriptPath)
    }

    let result = transformFunction.call(withArguments: [input])
    if let exceptionMessage {
        throw ScriptRunnerError.scriptException(message: exceptionMessage)
    }
    guard let output = result?.toString() else {
        throw ScriptRunnerError.transformReturnedNoText(commandID: commandID)
    }
    let outputData = Data(output.utf8)
    guard outputData.count <= maximumOutputBytes else {
        throw ScriptRunnerError.outputTooLarge(commandID: commandID, maxBytes: maximumOutputBytes)
    }
    FileHandle.standardOutput.write(outputData)
}

do {
    try run()
} catch {
    let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}
