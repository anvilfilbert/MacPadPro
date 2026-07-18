import Foundation

public enum ScriptTextCommandError: LocalizedError, Equatable {
    case helperMissing(path: String)
    case scriptFileTooLarge(path: String, maxBytes: Int)
    case inputTooLarge(commandID: String, maxBytes: Int)
    case outputTooLarge(commandID: String, maxBytes: Int)
    case commandTimedOut(commandID: String, seconds: Int)
    case helperFailed(commandID: String, statusCode: Int32, message: String)
    case outputCouldNotDecode(commandID: String)

    public var errorDescription: String? {
        switch self {
        case let .helperMissing(path):
            "Plugin script runner is missing: \(path). Rebuild or reinstall MacPad Pro."
        case let .scriptFileTooLarge(path, maxBytes):
            "Plugin script is too large. Maximum allowed size is \(maxBytes) bytes: \(path)."
        case let .inputTooLarge(commandID, maxBytes):
            "Plugin command '\(commandID)' input is too large. Maximum allowed size is \(maxBytes) bytes."
        case let .outputTooLarge(commandID, maxBytes):
            "Plugin command '\(commandID)' output is too large. Maximum allowed size is \(maxBytes) bytes."
        case let .commandTimedOut(commandID, seconds):
            "Plugin command '\(commandID)' timed out after \(seconds) seconds."
        case let .helperFailed(commandID, statusCode, message):
            "Plugin command '\(commandID)' failed in script runner with status \(statusCode): \(message)"
        case let .outputCouldNotDecode(commandID):
            "Plugin command '\(commandID)' returned non-UTF-8 output."
        }
    }
}

public struct ScriptTextCommand: Sendable, Equatable {
    public let id: String
    public let title: String
    public let scriptURL: URL

    private static let maximumInputBytes = 256 * 1024
    private static let maximumScriptBytes = 256 * 1024
    private static let maximumOutputBytes = 512 * 1024
    private static let timeoutSeconds = 3

    public init(id: String, title: String, scriptURL: URL) {
        self.id = id
        self.title = title
        self.scriptURL = scriptURL
    }

    public func transform(_ text: String) throws -> String {
        try validateScriptSize()
        let inputData = Data(text.utf8)
        guard inputData.count <= Self.maximumInputBytes else {
            throw ScriptTextCommandError.inputTooLarge(commandID: id, maxBytes: Self.maximumInputBytes)
        }

        let helperURL = try scriptRunnerURL()
        let process = Process()
        process.executableURL = helperURL
        process.arguments = [id, scriptURL.path]

        let standardInput = Pipe()
        let standardOutput = Pipe()
        let standardError = Pipe()
        process.standardInput = standardInput
        process.standardOutput = standardOutput
        process.standardError = standardError

        let terminationSemaphore = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in terminationSemaphore.signal() }
        try process.run()
        standardInput.fileHandleForWriting.write(inputData)
        try standardInput.fileHandleForWriting.close()

        if terminationSemaphore.wait(timeout: .now() + .seconds(Self.timeoutSeconds)) == .timedOut {
            process.terminate()
            throw ScriptTextCommandError.commandTimedOut(commandID: id, seconds: Self.timeoutSeconds)
        }

        let outputData = standardOutput.fileHandleForReading.readDataToEndOfFile()
        let errorData = standardError.fileHandleForReading.readDataToEndOfFile()
        guard process.terminationStatus == 0 else {
            let message = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown script runner error."
            throw ScriptTextCommandError.helperFailed(commandID: id, statusCode: process.terminationStatus, message: message)
        }
        guard outputData.count <= Self.maximumOutputBytes else {
            throw ScriptTextCommandError.outputTooLarge(commandID: id, maxBytes: Self.maximumOutputBytes)
        }
        guard let output = String(data: outputData, encoding: .utf8) else {
            throw ScriptTextCommandError.outputCouldNotDecode(commandID: id)
        }
        return output
    }

    public var textCommand: TextCommand {
        TextCommand(id: id, title: title) { text in
            try transform(text)
        }
    }

    private func validateScriptSize() throws {
        let attributes = try FileManager.default.attributesOfItem(atPath: scriptURL.path)
        if let size = attributes[.size] as? NSNumber, size.intValue > Self.maximumScriptBytes {
            throw ScriptTextCommandError.scriptFileTooLarge(path: scriptURL.path, maxBytes: Self.maximumScriptBytes)
        }
    }

    private func scriptRunnerURL() throws -> URL {
        let executableDirectory = Bundle.main.executableURL?.deletingLastPathComponent()
        let candidates = [
            executableDirectory?.appendingPathComponent("MacPadProScriptRunner"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent(".build/debug/MacPadProScriptRunner"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent(".build/release/MacPadProScriptRunner")
        ].compactMap { $0 }

        if let helperURL = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0.path) }) {
            return helperURL
        }
        throw ScriptTextCommandError.helperMissing(path: candidates.first?.path ?? "MacPadProScriptRunner")
    }
}
