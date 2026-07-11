import CryptoKit
import Foundation

public enum ExtensionPackageDownloadError: LocalizedError, Equatable {
    case packageDoesNotMatchCatalog(expectedID: String, actualID: String)
    case unsupportedPackageFormat(extensionID: String, packageFormatVersion: Int, supportedPackageFormatVersion: Int)
    case incompatibleAppVersion(extensionID: String, minimumMacPadProVersion: String, currentMacPadProVersion: String)
    case invalidPackageFilePath(file: String)
    case themeResourceMissing(resourceFile: String)
    case scriptFileMissing(scriptFile: String)
    case resourceFileMissing(resourceFile: String)
    case resourceChecksumMismatch(expectedSHA256: String, actualSHA256: String, resourceFile: String)
    case scriptChecksumMismatch(expectedSHA256: String, actualSHA256: String, scriptFile: String)

    public var errorDescription: String? {
        switch self {
        case let .packageDoesNotMatchCatalog(expectedID, actualID):
            "Downloaded package id '\(actualID)' does not match catalog extension id '\(expectedID)'."
        case let .unsupportedPackageFormat(extensionID, packageFormatVersion, supportedPackageFormatVersion):
            "Extension '\(extensionID)' uses package format \(packageFormatVersion), but this app supports format \(supportedPackageFormatVersion)."
        case let .incompatibleAppVersion(extensionID, minimumMacPadProVersion, currentMacPadProVersion):
            "Extension '\(extensionID)' requires MacPad Pro \(minimumMacPadProVersion) or newer. Current version is \(currentMacPadProVersion)."
        case let .invalidPackageFilePath(file):
            "Package file path '\(file)' is invalid. Package files must be simple file names inside the extension directory."
        case let .themeResourceMissing(resourceFile):
            "Theme resource '\(resourceFile)' is not declared in the package resources list."
        case let .scriptFileMissing(scriptFile):
            "Script '\(scriptFile)' is missing from the local extension package."
        case let .resourceFileMissing(resourceFile):
            "Resource '\(resourceFile)' is missing from the local extension package."
        case let .resourceChecksumMismatch(expectedSHA256, actualSHA256, resourceFile):
            "Resource '\(resourceFile)' checksum mismatch. Expected SHA-256 \(expectedSHA256), got \(actualSHA256)."
        case let .scriptChecksumMismatch(expectedSHA256, actualSHA256, scriptFile):
            "Script '\(scriptFile)' checksum mismatch. Expected SHA-256 \(expectedSHA256), got \(actualSHA256)."
        }
    }
}

public struct ExtensionPackageValidator: Sendable {
    public let supportedPackageFormatVersion = 1
    public let currentMacPadProVersion: String

    public init() {
        self.init(currentMacPadProVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0")
    }

    public init(currentMacPadProVersion: String) {
        self.currentMacPadProVersion = currentMacPadProVersion
    }

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
        try validateCompatibility(manifest)
        try validatePackageFileReferences(manifest)
    }

    public func validateResourceFile(_ resourceURL: URL, resource: ExtensionResourceFile) throws {
        try validatePackageFilePath(resource.file)
        guard FileManager.default.fileExists(atPath: resourceURL.path) else {
            throw ExtensionPackageDownloadError.resourceFileMissing(resourceFile: resource.file)
        }
        let resourceData = try Data(contentsOf: resourceURL)
        try validateResourceData(resourceData, resource: resource)
    }

    public func validateResourceData(_ resourceData: Data, resource: ExtensionResourceFile) throws {
        let actualSHA256 = sha256Hex(for: resourceData)
        guard actualSHA256.caseInsensitiveCompare(resource.sourceSHA256) == .orderedSame else {
            throw ExtensionPackageDownloadError.resourceChecksumMismatch(
                expectedSHA256: resource.sourceSHA256,
                actualSHA256: actualSHA256,
                resourceFile: resource.file
            )
        }
    }

    public func validateScriptFile(_ scriptURL: URL, scriptCommand: ExtensionScriptCommand) throws {
        try validatePackageFilePath(scriptCommand.scriptFile)
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

    private func validateCompatibility(_ manifest: ExtensionPackageManifest) throws {
        guard manifest.packageFormatVersion <= supportedPackageFormatVersion else {
            throw ExtensionPackageDownloadError.unsupportedPackageFormat(
                extensionID: manifest.id,
                packageFormatVersion: manifest.packageFormatVersion,
                supportedPackageFormatVersion: supportedPackageFormatVersion
            )
        }
        guard let minimumMacPadProVersion = manifest.minimumMacPadProVersion else { return }
        guard compareVersionStrings(currentMacPadProVersion, minimumMacPadProVersion) != .orderedAscending else {
            throw ExtensionPackageDownloadError.incompatibleAppVersion(
                extensionID: manifest.id,
                minimumMacPadProVersion: minimumMacPadProVersion,
                currentMacPadProVersion: currentMacPadProVersion
            )
        }
    }

    private func validatePackageFileReferences(_ manifest: ExtensionPackageManifest) throws {
        if let scriptCommand = manifest.scriptCommand {
            try validatePackageFilePath(scriptCommand.scriptFile)
        }
        for resource in manifest.resources {
            try validatePackageFilePath(resource.file)
        }
        guard let themeResource = manifest.themeResource else { return }
        try validatePackageFilePath(themeResource.file)
        guard manifest.resources.contains(where: { $0.file == themeResource.file }) else {
            throw ExtensionPackageDownloadError.themeResourceMissing(resourceFile: themeResource.file)
        }
    }

    private func validatePackageFilePath(_ file: String) throws {
        guard !file.isEmpty,
              !file.contains("/"),
              !file.contains("\\"),
              file != ".",
              file != "..",
              !file.hasPrefix("."),
              !file.contains("..") else {
            throw ExtensionPackageDownloadError.invalidPackageFilePath(file: file)
        }
    }
}

func sha256Hex(for data: Data) -> String {
    SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
}

func compareVersionStrings(_ lhs: String, _ rhs: String) -> ComparisonResult {
    let lhsParts = lhs.split(separator: ".").map { Int($0) ?? 0 }
    let rhsParts = rhs.split(separator: ".").map { Int($0) ?? 0 }
    let count = max(lhsParts.count, rhsParts.count)
    for index in 0..<count {
        let left = index < lhsParts.count ? lhsParts[index] : 0
        let right = index < rhsParts.count ? rhsParts[index] : 0
        if left < right { return .orderedAscending }
        if left > right { return .orderedDescending }
    }
    return .orderedSame
}
