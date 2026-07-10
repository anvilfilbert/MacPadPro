import CryptoKit
import Foundation

public enum ExtensionPackageDownloadError: LocalizedError, Equatable {
    case packageDoesNotMatchCatalog(expectedID: String, actualID: String)
    case scriptFileMissing(scriptFile: String)
    case scriptChecksumMismatch(expectedSHA256: String, actualSHA256: String, scriptFile: String)

    public var errorDescription: String? {
        switch self {
        case let .packageDoesNotMatchCatalog(expectedID, actualID):
            "Downloaded package id '\(actualID)' does not match catalog extension id '\(expectedID)'."
        case let .scriptFileMissing(scriptFile):
            "Script '\(scriptFile)' is missing from the local extension package."
        case let .scriptChecksumMismatch(expectedSHA256, actualSHA256, scriptFile):
            "Script '\(scriptFile)' checksum mismatch. Expected SHA-256 \(expectedSHA256), got \(actualSHA256)."
        }
    }
}

public struct ExtensionPackageValidator: Sendable {
    public init() {}

    public func validateManifest(_ manifest: ExtensionPackageManifest, matches extensionItem: DownloadableExtension) throws {
        guard manifest.id == extensionItem.id,
              manifest.title == extensionItem.title,
              manifest.description == extensionItem.description,
              manifest.version == extensionItem.version,
              manifest.kind == extensionItem.kind else {
            throw ExtensionPackageDownloadError.packageDoesNotMatchCatalog(
                expectedID: extensionItem.id,
                actualID: manifest.id
            )
        }
    }

    public func validateScriptFile(_ scriptURL: URL, scriptCommand: ExtensionScriptCommand) throws {
        guard FileManager.default.fileExists(atPath: scriptURL.path) else {
            throw ExtensionPackageDownloadError.scriptFileMissing(scriptFile: scriptCommand.scriptFile)
        }
        guard let expectedSHA256 = scriptCommand.sourceSHA256 else { return }
        let scriptData = try Data(contentsOf: scriptURL)
        try validateScriptData(scriptData, scriptCommand: scriptCommand, expectedSHA256: expectedSHA256)
    }

    public func validateScriptData(_ scriptData: Data, scriptCommand: ExtensionScriptCommand) throws {
        guard let expectedSHA256 = scriptCommand.sourceSHA256 else { return }
        try validateScriptData(scriptData, scriptCommand: scriptCommand, expectedSHA256: expectedSHA256)
    }

    private func validateScriptData(_ scriptData: Data, scriptCommand: ExtensionScriptCommand, expectedSHA256: String) throws {
        let actualSHA256 = sha256Hex(for: scriptData)
        guard actualSHA256.caseInsensitiveCompare(expectedSHA256) == .orderedSame else {
            throw ExtensionPackageDownloadError.scriptChecksumMismatch(
                expectedSHA256: expectedSHA256,
                actualSHA256: actualSHA256,
                scriptFile: scriptCommand.scriptFile
            )
        }
    }
}

func sha256Hex(for data: Data) -> String {
    SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
}
