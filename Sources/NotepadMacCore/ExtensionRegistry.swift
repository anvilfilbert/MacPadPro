import AppKit
import CryptoKit
import Foundation
import JavaScriptCore

public struct EditorTheme: @unchecked Sendable {
    public let id: String
    public let name: String
    public let textColor: NSColor
    public let backgroundColor: NSColor
    public let insertionPointColor: NSColor
    public let statusTextColor: NSColor
    public let statusBackgroundColor: NSColor
}

public struct LanguageDefinition: Sendable {
    public let id: String
    public let name: String
    public let fileExtensions: [String]
    public let shebangHints: [String]
}

public protocol CodeFormatter: Sendable {
    var id: String { get }
    var name: String { get }
    var supportedLanguageIDs: Set<String> { get }

    func format(_ text: String) throws -> String
}

public struct TextCommand: Sendable {
    public let id: String
    public let title: String
    private let transformText: @Sendable (String) throws -> String

    public init(id: String, title: String, transform: @escaping @Sendable (String) throws -> String) {
        self.id = id
        self.title = title
        transformText = transform
    }

    public func transform(_ text: String) throws -> String {
        try transformText(text)
    }
}

public struct DocumentBrowserExtension: Sendable {
    public let id: String
    public let title: String
    public let opensDetachedWindow: Bool
    public let isResizable: Bool
    public let isClosable: Bool
}

public struct ClipboardExtension: Sendable {
    public let id: String
    public let title: String
    public let slotCount: Int
}

public struct ExtensionMenuAction: Sendable {
    public let id: String
    public let title: String
    public let opensDetachedWindow: Bool
    public let isResizable: Bool
    public let isClosable: Bool

    public init(
        id: String,
        title: String,
        opensDetachedWindow: Bool,
        isResizable: Bool,
        isClosable: Bool
    ) {
        self.id = id
        self.title = title
        self.opensDetachedWindow = opensDetachedWindow
        self.isResizable = isResizable
        self.isClosable = isClosable
    }
}

public struct DocumentBrowserItem: Sendable, Equatable {
    public let id: String
    public let title: String
    public let location: String

    public init(id: String, title: String, location: String) {
        self.id = id
        self.title = title
        self.location = location
    }
}

public struct ExtensionContribution: Sendable {
    public let catalogEntry: DownloadableExtension
    public let themes: [EditorTheme]
    public let textCommands: [TextCommand]
    public let formatters: [any CodeFormatter]
    public let documentBrowsers: [DocumentBrowserExtension]
    public let clipboards: [ClipboardExtension]
    public let aiTextTasks: [AITextTask]
    public let aiSmartSearches: [AISmartSearchExtension]
    public let markdownPreviews: [ExtensionMenuAction]
    public let exportTools: [ExtensionMenuAction]
    public let documentStatistics: [ExtensionMenuAction]
    public let diffViewers: [ExtensionMenuAction]
    public let autoBackups: [ExtensionMenuAction]
    public let clipboardSnippets: [ExtensionMenuAction]
    public let fileOutlines: [ExtensionMenuAction]
    public let csvTableViewers: [ExtensionMenuAction]
    public let markdownTools: [ExtensionMenuAction]
    public let encodingLineEndings: [ExtensionMenuAction]
    public let focusModes: [ExtensionMenuAction]

    public init(
        catalogEntry: DownloadableExtension,
        themes: [EditorTheme],
        textCommands: [TextCommand],
        formatters: [any CodeFormatter],
        documentBrowsers: [DocumentBrowserExtension],
        clipboards: [ClipboardExtension],
        aiTextTasks: [AITextTask],
        aiSmartSearches: [AISmartSearchExtension],
        markdownPreviews: [ExtensionMenuAction],
        exportTools: [ExtensionMenuAction],
        documentStatistics: [ExtensionMenuAction],
        diffViewers: [ExtensionMenuAction],
        autoBackups: [ExtensionMenuAction],
        clipboardSnippets: [ExtensionMenuAction],
        fileOutlines: [ExtensionMenuAction],
        csvTableViewers: [ExtensionMenuAction],
        markdownTools: [ExtensionMenuAction],
        encodingLineEndings: [ExtensionMenuAction],
        focusModes: [ExtensionMenuAction]
    ) {
        self.catalogEntry = catalogEntry
        self.themes = themes
        self.textCommands = textCommands
        self.formatters = formatters
        self.documentBrowsers = documentBrowsers
        self.clipboards = clipboards
        self.aiTextTasks = aiTextTasks
        self.aiSmartSearches = aiSmartSearches
        self.markdownPreviews = markdownPreviews
        self.exportTools = exportTools
        self.documentStatistics = documentStatistics
        self.diffViewers = diffViewers
        self.autoBackups = autoBackups
        self.clipboardSnippets = clipboardSnippets
        self.fileOutlines = fileOutlines
        self.csvTableViewers = csvTableViewers
        self.markdownTools = markdownTools
        self.encodingLineEndings = encodingLineEndings
        self.focusModes = focusModes
    }

    public init(catalogEntry: DownloadableExtension, textCommands: [TextCommand]) {
        self.init(
            catalogEntry: catalogEntry,
            themes: [],
            textCommands: textCommands,
            formatters: [],
            documentBrowsers: [],
            clipboards: [],
            aiTextTasks: [],
            aiSmartSearches: [],
            markdownPreviews: [],
            exportTools: [],
            documentStatistics: [],
            diffViewers: [],
            autoBackups: [],
            clipboardSnippets: [],
            fileOutlines: [],
            csvTableViewers: [],
            markdownTools: [],
            encodingLineEndings: [],
            focusModes: []
        )
    }

    public static let builtIn: [ExtensionContribution] = BuiltInExtensions.contributions
}

public enum ExtensionKind: String, Codable, Sendable {
    case documentBrowser
    case theme
    case language
    case formatter
    case textCommand
    case clipboard
    case aiTextTask
    case aiSmartSearch
    case markdownPreview
    case exportTools
    case documentStatistics
    case diffViewer
    case autoBackup
    case clipboardSnippets
    case fileOutline
    case csvTableViewer
    case markdownTools
    case encodingLineEndings
    case focusMode
}

public enum ExtensionPermission: String, Codable, Sendable, Equatable {
    case readSelectedText
    case editSelectedText
    case readDocumentText
    case openDetachedWindow
    case localStorage
    case networkAccess
}

public struct ExtensionScriptCommand: Codable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let scriptFile: String
    public let sourceURL: URL?
    public let sourceSHA256: String?

    public init(id: String, title: String, scriptFile: String, sourceURL: URL?, sourceSHA256: String?) {
        self.id = id
        self.title = title
        self.scriptFile = scriptFile
        self.sourceURL = sourceURL
        self.sourceSHA256 = sourceSHA256
    }
}

public struct DownloadableExtension: Codable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let description: String
    public let version: String
    public let kind: ExtensionKind
    public let author: String?
    public let permissions: [ExtensionPermission]
    public let downloadURL: URL

    public init(id: String, title: String, description: String, version: String, kind: ExtensionKind, downloadURL: URL) {
        self.id = id
        self.title = title
        self.description = description
        self.version = version
        self.kind = kind
        self.author = nil
        self.permissions = []
        self.downloadURL = downloadURL
    }

    public init(
        id: String,
        title: String,
        description: String,
        version: String,
        kind: ExtensionKind,
        author: String?,
        permissions: [ExtensionPermission],
        downloadURL: URL
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.version = version
        self.kind = kind
        self.author = author
        self.permissions = permissions
        self.downloadURL = downloadURL
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case version
        case kind
        case author
        case permissions
        case downloadURL
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        version = try container.decode(String.self, forKey: .version)
        kind = try container.decode(ExtensionKind.self, forKey: .kind)
        author = try container.decodeIfPresent(String.self, forKey: .author)
        permissions = try container.decodeIfPresent([ExtensionPermission].self, forKey: .permissions) ?? []
        downloadURL = try container.decode(URL.self, forKey: .downloadURL)
    }
}

public struct ExtensionPackageManifest: Codable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let description: String
    public let version: String
    public let kind: ExtensionKind
    public let author: String?
    public let permissions: [ExtensionPermission]
    public let scriptCommand: ExtensionScriptCommand?

    public init(id: String, title: String, description: String, version: String, kind: ExtensionKind) {
        self.id = id
        self.title = title
        self.description = description
        self.version = version
        self.kind = kind
        self.author = nil
        self.permissions = []
        self.scriptCommand = nil
    }

    public init(
        id: String,
        title: String,
        description: String,
        version: String,
        kind: ExtensionKind,
        author: String?,
        permissions: [ExtensionPermission],
        scriptCommand: ExtensionScriptCommand?
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.version = version
        self.kind = kind
        self.author = author
        self.permissions = permissions
        self.scriptCommand = scriptCommand
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case version
        case kind
        case author
        case permissions
        case scriptCommand
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        version = try container.decode(String.self, forKey: .version)
        kind = try container.decode(ExtensionKind.self, forKey: .kind)
        author = try container.decodeIfPresent(String.self, forKey: .author)
        permissions = try container.decodeIfPresent([ExtensionPermission].self, forKey: .permissions) ?? []
        scriptCommand = try container.decodeIfPresent(ExtensionScriptCommand.self, forKey: .scriptCommand)
    }
}

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

public struct ExtensionPackageStore {
    public let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    public func packageURL(for extensionID: String) -> URL {
        directory.appendingPathComponent("\(extensionID).macpadproext")
    }

    public func scriptURL(for extensionID: String, scriptFile: String) -> URL {
        directory
            .appendingPathComponent(extensionID, isDirectory: true)
            .appendingPathComponent(scriptFile)
    }

    public func hasPackage(for extensionID: String) -> Bool {
        FileManager.default.fileExists(atPath: packageURL(for: extensionID).path)
    }

    public func hasValidatedPackage(for extensionItem: DownloadableExtension) -> Bool {
        do {
            try validateInstalledPackage(for: extensionItem)
            return true
        } catch {
            return false
        }
    }

    public func validateInstalledPackage(for extensionItem: DownloadableExtension) throws {
        let manifest = try installedManifest(for: extensionItem.id)
        try manifest.validate(matches: extensionItem)
        try validateInstalledScript(for: manifest)
    }

    public func installedManifest(for extensionID: String) throws -> ExtensionPackageManifest {
        let packageData = try Data(contentsOf: packageURL(for: extensionID))
        return try JSONDecoder().decode(ExtensionPackageManifest.self, from: packageData)
    }

    public func installedVersion(for extensionID: String) throws -> String {
        try installedManifest(for: extensionID).version
    }

    public func hasUpdateAvailable(for extensionItem: DownloadableExtension) -> Bool {
        guard let installedVersion = try? installedVersion(for: extensionItem.id) else { return false }
        return compareVersionStrings(installedVersion, extensionItem.version) == .orderedAscending
    }

    public func scriptCommands(for installedExtensions: InstalledExtensions) -> [ScriptTextCommand] {
        installedExtensions.installedIDs
            .sorted()
            .filter(installedExtensions.isActive)
            .compactMap { extensionID in
                guard let manifest = try? installedManifest(for: extensionID),
                      manifest.kind == .textCommand,
                      let scriptCommand = manifest.scriptCommand else { return nil }
                let scriptURL = scriptURL(for: manifest.id, scriptFile: scriptCommand.scriptFile)
                guard FileManager.default.fileExists(atPath: scriptURL.path) else { return nil }
                return ScriptTextCommand(id: scriptCommand.id, title: scriptCommand.title, scriptURL: scriptURL)
            }
    }

    private func validateInstalledScript(for manifest: ExtensionPackageManifest) throws {
        guard let scriptCommand = manifest.scriptCommand else { return }
        let scriptURL = scriptURL(for: manifest.id, scriptFile: scriptCommand.scriptFile)
        guard FileManager.default.fileExists(atPath: scriptURL.path) else {
            throw ExtensionPackageDownloadError.scriptFileMissing(scriptFile: scriptCommand.scriptFile)
        }
        guard let expectedSHA256 = scriptCommand.sourceSHA256 else { return }
        let scriptData = try Data(contentsOf: scriptURL)
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

extension ExtensionPackageManifest {
    func validate(matches extensionItem: DownloadableExtension) throws {
        guard id == extensionItem.id,
              title == extensionItem.title,
              description == extensionItem.description,
              version == extensionItem.version,
              kind == extensionItem.kind else {
            throw ExtensionPackageDownloadError.packageDoesNotMatchCatalog(
                expectedID: extensionItem.id,
                actualID: id
            )
        }
    }
}

public struct ExtensionCatalog: Codable, Sendable, Equatable {
    public let extensions: [DownloadableExtension]

    public static let `default` = ExtensionCatalog(extensions: ExtensionContribution.builtIn.map(\.catalogEntry))

    public init(extensions: [DownloadableExtension]) {
        self.extensions = extensions
    }

    public func `extension`(withID id: String) -> DownloadableExtension? {
        extensions.first { $0.id == id }
    }

    public func search(matching query: String) -> [DownloadableExtension] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedQuery.isEmpty else { return extensions }

        return extensions.filter { extensionItem in
            [
                extensionItem.id,
                extensionItem.title,
                extensionItem.description,
                extensionItem.kind.rawValue
            ].contains { $0.lowercased().contains(normalizedQuery) }
        }
    }
}

public enum ExtensionRepository {
    public static let macPadProGitHubCatalogURL = URL(
        string: "https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/catalog.json"
    )!
}

public struct ExtensionRepositoryCatalogLoader {
    public init() {}

    public func loadCatalog(from url: URL = ExtensionRepository.macPadProGitHubCatalogURL) throws -> ExtensionCatalog {
        let catalogData = try Data(contentsOf: url)
        return try JSONDecoder().decode(ExtensionCatalog.self, from: catalogData)
    }
}

public struct ExtensionPackageDownloader {
    public init() {}

    @discardableResult
    public func download(_ extensionItem: DownloadableExtension, into directory: URL) throws -> URL {
        let packageData = try Data(contentsOf: extensionItem.downloadURL)
        let manifest = try JSONDecoder().decode(ExtensionPackageManifest.self, from: packageData)
        try manifest.validate(matches: extensionItem)

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = ExtensionPackageStore(directory: directory)
        if let scriptCommand = manifest.scriptCommand,
           let sourceURL = scriptCommand.sourceURL {
            let scriptData = try Data(contentsOf: sourceURL)
            if let expectedSHA256 = scriptCommand.sourceSHA256 {
                let actualSHA256 = sha256Hex(for: scriptData)
                guard actualSHA256.caseInsensitiveCompare(expectedSHA256) == .orderedSame else {
                    throw ExtensionPackageDownloadError.scriptChecksumMismatch(
                        expectedSHA256: expectedSHA256,
                        actualSHA256: actualSHA256,
                        scriptFile: scriptCommand.scriptFile
                    )
                }
            }
            let scriptDestinationURL = store.scriptURL(for: extensionItem.id, scriptFile: scriptCommand.scriptFile)
            try FileManager.default.createDirectory(at: scriptDestinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try scriptData.write(to: scriptDestinationURL, options: .atomic)
        }
        let destinationURL = store.packageURL(for: extensionItem.id)
        try packageData.write(to: destinationURL, options: .atomic)
        return destinationURL
    }
}

func sha256Hex(for data: Data) -> String {
    SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
}

private func compareVersionStrings(_ lhs: String, _ rhs: String) -> ComparisonResult {
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

public struct InstalledExtensions: Codable, Sendable, Equatable {
    public private(set) var installedIDs: Set<String>
    public private(set) var deactivatedIDs: Set<String>

    public static let bundledDefault = InstalledExtensions(installedIDs: BuiltInExtensions.defaultInstalledExtensionIDs)

    private enum CodingKeys: String, CodingKey {
        case installedIDs
        case deactivatedIDs
    }

    public init(installedIDs: Set<String>, deactivatedIDs: Set<String> = []) {
        self.installedIDs = installedIDs
        self.deactivatedIDs = deactivatedIDs.intersection(installedIDs)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let installedIDs = try container.decode(Set<String>.self, forKey: .installedIDs)
        let deactivatedIDs = try container.decodeIfPresent(Set<String>.self, forKey: .deactivatedIDs) ?? []
        self.init(installedIDs: installedIDs, deactivatedIDs: deactivatedIDs)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(installedIDs, forKey: .installedIDs)
        try container.encode(deactivatedIDs, forKey: .deactivatedIDs)
    }

    public func isInstalled(_ id: String) -> Bool {
        installedIDs.contains(id)
    }

    public func isActive(_ id: String) -> Bool {
        installedIDs.contains(id) && !deactivatedIDs.contains(id)
    }

    public mutating func load(_ id: String) {
        installedIDs.insert(id)
        deactivatedIDs.remove(id)
    }

    public mutating func update(_ id: String) {
        let wasDeactivated = deactivatedIDs.contains(id)
        installedIDs.insert(id)
        if wasDeactivated {
            deactivatedIDs.insert(id)
        }
    }

    public mutating func activate(_ id: String) {
        guard installedIDs.contains(id) else { return }
        deactivatedIDs.remove(id)
    }

    public mutating func deactivate(_ id: String) {
        guard installedIDs.contains(id) else { return }
        deactivatedIDs.insert(id)
    }

    public mutating func delete(_ id: String) {
        installedIDs.remove(id)
        deactivatedIDs.remove(id)
    }
}

public struct ExtensionRegistry: Sendable {
    public let themes: [EditorTheme]
    public let languages: [LanguageDefinition]
    public let textCommands: [TextCommand]
    public let formatters: [any CodeFormatter]
    public let documentBrowsers: [DocumentBrowserExtension]
    public let clipboards: [ClipboardExtension]
    public let aiTextTasks: [AITextTask]
    public let aiSmartSearches: [AISmartSearchExtension]
    public let markdownPreviews: [ExtensionMenuAction]
    public let exportTools: [ExtensionMenuAction]
    public let documentStatistics: [ExtensionMenuAction]
    public let diffViewers: [ExtensionMenuAction]
    public let autoBackups: [ExtensionMenuAction]
    public let clipboardSnippets: [ExtensionMenuAction]
    public let fileOutlines: [ExtensionMenuAction]
    public let csvTableViewers: [ExtensionMenuAction]
    public let markdownTools: [ExtensionMenuAction]
    public let encodingLineEndings: [ExtensionMenuAction]
    public let focusModes: [ExtensionMenuAction]

    public static let `default` = loaded(installedExtensions: .bundledDefault)

    public static func loaded(installedExtensions: InstalledExtensions) -> ExtensionRegistry {
        loaded(installedExtensions: installedExtensions, packageStore: nil, contributions: ExtensionContribution.builtIn)
    }

    public static func loaded(installedExtensions: InstalledExtensions, packageStore: ExtensionPackageStore) -> ExtensionRegistry {
        loaded(installedExtensions: installedExtensions, packageStore: packageStore as ExtensionPackageStore?, contributions: ExtensionContribution.builtIn)
    }

    public static func loaded(installedExtensions: InstalledExtensions, contributions: [ExtensionContribution]) -> ExtensionRegistry {
        loaded(installedExtensions: installedExtensions, packageStore: nil, contributions: contributions)
    }

    private static func loaded(installedExtensions: InstalledExtensions, packageStore: ExtensionPackageStore?, contributions: [ExtensionContribution]) -> ExtensionRegistry {
        let activeContributions = contributions.filter { installedExtensions.isActive($0.catalogEntry.id) }
        let themes = BuiltInExtensions.systemThemes
            + activeContributions.flatMap(\.themes)
        let formatters = activeContributions.flatMap(\.formatters)
        let textCommands = BuiltInExtensions.coreTextCommands
            + activeContributions.flatMap(\.textCommands)
            + (packageStore?.scriptCommands(for: installedExtensions).map(\.textCommand) ?? [])
        let documentBrowsers = activeContributions.flatMap(\.documentBrowsers)
        let clipboards = activeContributions.flatMap(\.clipboards)
        let aiTextTasks = activeContributions.flatMap(\.aiTextTasks)
        let aiSmartSearches = activeContributions.flatMap(\.aiSmartSearches)
        let markdownPreviews = activeContributions.flatMap(\.markdownPreviews)
        let exportTools = activeContributions.flatMap(\.exportTools)
        let documentStatistics = activeContributions.flatMap(\.documentStatistics)
        let diffViewers = activeContributions.flatMap(\.diffViewers)
        let autoBackups = activeContributions.flatMap(\.autoBackups)
        let clipboardSnippets = activeContributions.flatMap(\.clipboardSnippets)
        let fileOutlines = activeContributions.flatMap(\.fileOutlines)
        let csvTableViewers = activeContributions.flatMap(\.csvTableViewers)
        let markdownTools = activeContributions.flatMap(\.markdownTools)
        let encodingLineEndings = activeContributions.flatMap(\.encodingLineEndings)
        let focusModes = activeContributions.flatMap(\.focusModes)

        return ExtensionRegistry(
            themes: themes,
            languages: BuiltInExtensions.languages,
            textCommands: textCommands,
            formatters: formatters,
            documentBrowsers: documentBrowsers,
            clipboards: clipboards,
            aiTextTasks: aiTextTasks,
            aiSmartSearches: aiSmartSearches,
            markdownPreviews: markdownPreviews,
            exportTools: exportTools,
            documentStatistics: documentStatistics,
            diffViewers: diffViewers,
            autoBackups: autoBackups,
            clipboardSnippets: clipboardSnippets,
            fileOutlines: fileOutlines,
            csvTableViewers: csvTableViewers,
            markdownTools: markdownTools,
            encodingLineEndings: encodingLineEndings,
            focusModes: focusModes
        )
    }

    public func detectLanguage(for fileURL: URL?, text: String) -> String {
        if let language = detectLanguageDefinition(for: fileURL, text: text) {
            return language.name
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("#!/") {
            return "Script"
        }

        return "Plain Text"
    }

    public func detectLanguageDefinition(for fileURL: URL?, text: String) -> LanguageDefinition? {
        if let fileURL {
            let ext = fileURL.pathExtension.lowercased()
            if let language = languages.first(where: { $0.fileExtensions.contains(ext) }) {
                return language
            }
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("#!/"),
           let firstLine = trimmed.split(separator: "\n", maxSplits: 1).first {
            let line = firstLine.lowercased()
            if let language = languages.first(where: { definition in
                definition.shebangHints.contains(where: line.contains)
            }) {
                return language
            }
            return nil
        }
        if looksLikeJSON(trimmed) {
            return languages.first { $0.id == "json" }
        }
        if trimmed.hasPrefix("<!doctype html") || trimmed.hasPrefix("<html") {
            return languages.first { $0.id == "html" }
        }
        return languages.first { $0.id == "plain-text" }
    }

    public func formatter(forLanguageID languageID: String) -> (any CodeFormatter)? {
        formatters.first { $0.supportedLanguageIDs.contains(languageID) }
    }

    public func formatter(named formatterID: String) -> (any CodeFormatter)? {
        formatters.first { $0.id == formatterID }
    }

    private func looksLikeJSON(_ text: String) -> Bool {
        guard let first = text.first, let last = text.last else { return false }
        return (first == "{" && last == "}") || (first == "[" && last == "]")
    }
}

private enum BuiltInExtensions {
    static let defaultInstalledExtensionIDs: Set<String> = []

    static let systemThemes: [EditorTheme] = [
        EditorTheme(
            id: "system",
            name: "System",
            textColor: .textColor,
            backgroundColor: .textBackgroundColor,
            insertionPointColor: .textColor,
            statusTextColor: .secondaryLabelColor,
            statusBackgroundColor: .windowBackgroundColor
        )
    ]

    static let languages: [LanguageDefinition] = [
        LanguageDefinition(id: "shell", name: "Shell", fileExtensions: ["bash", "sh", "zsh"], shebangHints: ["bash", "sh", "zsh"]),
        LanguageDefinition(id: "c", name: "C", fileExtensions: ["c"], shebangHints: []),
        LanguageDefinition(id: "cpp", name: "C++", fileExtensions: ["cc", "cpp", "cxx"], shebangHints: []),
        LanguageDefinition(id: "css", name: "CSS", fileExtensions: ["css"], shebangHints: []),
        LanguageDefinition(id: "go", name: "Go", fileExtensions: ["go"], shebangHints: []),
        LanguageDefinition(id: "c-header", name: "C/C++ Header", fileExtensions: ["h"], shebangHints: []),
        LanguageDefinition(id: "cpp-header", name: "C++ Header", fileExtensions: ["hpp", "hh", "hxx"], shebangHints: []),
        LanguageDefinition(id: "html", name: "HTML", fileExtensions: ["html", "htm"], shebangHints: []),
        LanguageDefinition(id: "java", name: "Java", fileExtensions: ["java"], shebangHints: []),
        LanguageDefinition(id: "javascript", name: "JavaScript", fileExtensions: ["js", "mjs"], shebangHints: ["node", "javascript"]),
        LanguageDefinition(id: "json", name: "JSON", fileExtensions: ["json"], shebangHints: []),
        LanguageDefinition(id: "kotlin", name: "Kotlin", fileExtensions: ["kt"], shebangHints: []),
        LanguageDefinition(id: "markdown", name: "Markdown", fileExtensions: ["md"], shebangHints: []),
        LanguageDefinition(id: "objective-cpp", name: "Objective-C++", fileExtensions: ["mm"], shebangHints: []),
        LanguageDefinition(id: "php", name: "PHP", fileExtensions: ["php", "phtml"], shebangHints: ["php"]),
        LanguageDefinition(id: "plist", name: "Property List", fileExtensions: ["plist"], shebangHints: []),
        LanguageDefinition(id: "python", name: "Python", fileExtensions: ["py"], shebangHints: ["python"]),
        LanguageDefinition(id: "ruby", name: "Ruby", fileExtensions: ["rb"], shebangHints: ["ruby"]),
        LanguageDefinition(id: "rust", name: "Rust", fileExtensions: ["rs"], shebangHints: []),
        LanguageDefinition(id: "swift", name: "Swift", fileExtensions: ["swift"], shebangHints: []),
        LanguageDefinition(id: "typescript", name: "TypeScript", fileExtensions: ["ts"], shebangHints: []),
        LanguageDefinition(id: "tsx", name: "TSX", fileExtensions: ["tsx"], shebangHints: []),
        LanguageDefinition(id: "plain-text", name: "Plain Text", fileExtensions: ["txt"], shebangHints: []),
        LanguageDefinition(id: "xml", name: "XML", fileExtensions: ["xml"], shebangHints: []),
        LanguageDefinition(id: "yaml", name: "YAML", fileExtensions: ["yaml", "yml"], shebangHints: [])
    ]

    static let coreTextCommands: [TextCommand] = [
        TextCommand(id: "trim-trailing-whitespace", title: "Trim Trailing Whitespace") { text in
            text
                .split(separator: "\n", omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .joined(separator: "\n")
        },
        TextCommand(id: "sort-lines", title: "Sort Lines") { text in
            text
                .split(separator: "\n", omittingEmptySubsequences: false)
                .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
                .joined(separator: "\n")
        },
        TextCommand(id: "uppercase", title: "Uppercase") { text in
            text.uppercased()
        },
        TextCommand(id: "lowercase", title: "Lowercase") { text in
            text.lowercased()
        }
    ]

    static let contributions: [ExtensionContribution] = [
        ExtensionContribution(catalogEntry: OpenDocumentsExtensionPackage.catalogEntry, documentBrowsers: OpenDocumentsExtensionPackage.documentBrowsers),
        ExtensionContribution(catalogEntry: JSONFormatterExtensionPackage.catalogEntry, textCommands: JSONFormatterExtensionPackage.textCommands, formatters: JSONFormatterExtensionPackage.formatters),
        ExtensionContribution(catalogEntry: CFamilyFormatterExtensionPackage.catalogEntry, formatters: CFamilyFormatterExtensionPackage.formatters),
        ExtensionContribution(catalogEntry: ClipboardSlotsExtensionPackage.catalogEntry, clipboards: ClipboardSlotsExtensionPackage.clipboards),
        ExtensionContribution(catalogEntry: AISummarizerExtensionPackage.catalogEntry, aiTextTasks: AISummarizerExtensionPackage.textTasks),
        ExtensionContribution(catalogEntry: AICodeExplainerExtensionPackage.catalogEntry, aiTextTasks: AICodeExplainerExtensionPackage.textTasks),
        ExtensionContribution(catalogEntry: AICodeRefactorExtensionPackage.catalogEntry, aiTextTasks: AICodeRefactorExtensionPackage.textTasks),
        ExtensionContribution(catalogEntry: AIMeetingNotesExtensionPackage.catalogEntry, aiTextTasks: AIMeetingNotesExtensionPackage.textTasks),
        ExtensionContribution(catalogEntry: AISmartSearchExtensionPackage.catalogEntry, aiSmartSearches: AISmartSearchExtensionPackage.smartSearches),
        ExtensionContribution(catalogEntry: ProThemesExtensionPackage.catalogEntry, themes: ProThemesExtensionPackage.themes),
        ExtensionContribution(catalogEntry: MarkdownPreviewExtensionPackage.catalogEntry, markdownPreviews: MarkdownPreviewExtensionPackage.actions),
        ExtensionContribution(catalogEntry: ExportToolsExtensionPackage.catalogEntry, exportTools: ExportToolsExtensionPackage.actions),
        ExtensionContribution(catalogEntry: DocumentStatisticsExtensionPackage.catalogEntry, documentStatistics: DocumentStatisticsExtensionPackage.actions),
        ExtensionContribution(catalogEntry: DiffViewerExtensionPackage.catalogEntry, diffViewers: DiffViewerExtensionPackage.actions),
        ExtensionContribution(catalogEntry: AutoBackupExtensionPackage.catalogEntry, autoBackups: AutoBackupExtensionPackage.actions),
        ExtensionContribution(catalogEntry: ClipboardSnippetsExtensionPackage.catalogEntry, clipboardSnippets: ClipboardSnippetsExtensionPackage.actions),
        ExtensionContribution(catalogEntry: FileOutlineExtensionPackage.catalogEntry, fileOutlines: FileOutlineExtensionPackage.actions),
        ExtensionContribution(catalogEntry: CSVTableViewerExtensionPackage.catalogEntry, csvTableViewers: CSVTableViewerExtensionPackage.actions),
        ExtensionContribution(catalogEntry: MarkdownToolsExtensionPackage.catalogEntry, markdownTools: MarkdownToolsExtensionPackage.actions),
        ExtensionContribution(catalogEntry: EncodingLineEndingsExtensionPackage.catalogEntry, encodingLineEndings: EncodingLineEndingsExtensionPackage.actions),
        ExtensionContribution(catalogEntry: FocusModeExtensionPackage.catalogEntry, focusModes: FocusModeExtensionPackage.actions),
        ExtensionContribution(catalogEntry: TitleCaseCommandExtensionPackage.catalogEntry)
    ]
}

private extension ExtensionContribution {
    init(catalogEntry: DownloadableExtension) {
        self.init(catalogEntry: catalogEntry, payload: .empty)
    }

    init(catalogEntry: DownloadableExtension, themes: [EditorTheme]) {
        self.init(catalogEntry: catalogEntry, payload: .themes(themes))
    }

    init(catalogEntry: DownloadableExtension, textCommands: [TextCommand], formatters: [any CodeFormatter]) {
        self.init(catalogEntry: catalogEntry, payload: .textCommandsAndFormatters(textCommands, formatters))
    }

    init(catalogEntry: DownloadableExtension, formatters: [any CodeFormatter]) {
        self.init(catalogEntry: catalogEntry, payload: .formatters(formatters))
    }

    init(catalogEntry: DownloadableExtension, documentBrowsers: [DocumentBrowserExtension]) {
        self.init(catalogEntry: catalogEntry, payload: .documentBrowsers(documentBrowsers))
    }

    init(catalogEntry: DownloadableExtension, clipboards: [ClipboardExtension]) {
        self.init(catalogEntry: catalogEntry, payload: .clipboards(clipboards))
    }

    init(catalogEntry: DownloadableExtension, aiTextTasks: [AITextTask]) {
        self.init(catalogEntry: catalogEntry, payload: .aiTextTasks(aiTextTasks))
    }

    init(catalogEntry: DownloadableExtension, aiSmartSearches: [AISmartSearchExtension]) {
        self.init(catalogEntry: catalogEntry, payload: .aiSmartSearches(aiSmartSearches))
    }

    init(catalogEntry: DownloadableExtension, markdownPreviews: [ExtensionMenuAction]) {
        self.init(catalogEntry: catalogEntry, payload: .markdownPreviews(markdownPreviews))
    }

    init(catalogEntry: DownloadableExtension, exportTools: [ExtensionMenuAction]) {
        self.init(catalogEntry: catalogEntry, payload: .exportTools(exportTools))
    }

    init(catalogEntry: DownloadableExtension, documentStatistics: [ExtensionMenuAction]) {
        self.init(catalogEntry: catalogEntry, payload: .documentStatistics(documentStatistics))
    }

    init(catalogEntry: DownloadableExtension, diffViewers: [ExtensionMenuAction]) {
        self.init(catalogEntry: catalogEntry, payload: .diffViewers(diffViewers))
    }

    init(catalogEntry: DownloadableExtension, autoBackups: [ExtensionMenuAction]) {
        self.init(catalogEntry: catalogEntry, payload: .autoBackups(autoBackups))
    }

    init(catalogEntry: DownloadableExtension, clipboardSnippets: [ExtensionMenuAction]) {
        self.init(catalogEntry: catalogEntry, payload: .clipboardSnippets(clipboardSnippets))
    }

    init(catalogEntry: DownloadableExtension, fileOutlines: [ExtensionMenuAction]) {
        self.init(catalogEntry: catalogEntry, payload: .fileOutlines(fileOutlines))
    }

    init(catalogEntry: DownloadableExtension, csvTableViewers: [ExtensionMenuAction]) {
        self.init(catalogEntry: catalogEntry, payload: .csvTableViewers(csvTableViewers))
    }

    init(catalogEntry: DownloadableExtension, markdownTools: [ExtensionMenuAction]) {
        self.init(catalogEntry: catalogEntry, payload: .markdownTools(markdownTools))
    }

    init(catalogEntry: DownloadableExtension, encodingLineEndings: [ExtensionMenuAction]) {
        self.init(catalogEntry: catalogEntry, payload: .encodingLineEndings(encodingLineEndings))
    }

    init(catalogEntry: DownloadableExtension, focusModes: [ExtensionMenuAction]) {
        self.init(catalogEntry: catalogEntry, payload: .focusModes(focusModes))
    }

    init(catalogEntry: DownloadableExtension, payload: ExtensionContributionPayload) {
        self.init(
            catalogEntry: catalogEntry,
            themes: payload.themes,
            textCommands: payload.textCommands,
            formatters: payload.formatters,
            documentBrowsers: payload.documentBrowsers,
            clipboards: payload.clipboards,
            aiTextTasks: payload.aiTextTasks,
            aiSmartSearches: payload.aiSmartSearches,
            markdownPreviews: payload.markdownPreviews,
            exportTools: payload.exportTools,
            documentStatistics: payload.documentStatistics,
            diffViewers: payload.diffViewers,
            autoBackups: payload.autoBackups,
            clipboardSnippets: payload.clipboardSnippets,
            fileOutlines: payload.fileOutlines,
            csvTableViewers: payload.csvTableViewers,
            markdownTools: payload.markdownTools,
            encodingLineEndings: payload.encodingLineEndings,
            focusModes: payload.focusModes
        )
    }
}

private enum ExtensionContributionPayload {
    case empty
    case themes([EditorTheme])
    case formatters([any CodeFormatter])
    case textCommandsAndFormatters([TextCommand], [any CodeFormatter])
    case documentBrowsers([DocumentBrowserExtension])
    case clipboards([ClipboardExtension])
    case aiTextTasks([AITextTask])
    case aiSmartSearches([AISmartSearchExtension])
    case markdownPreviews([ExtensionMenuAction])
    case exportTools([ExtensionMenuAction])
    case documentStatistics([ExtensionMenuAction])
    case diffViewers([ExtensionMenuAction])
    case autoBackups([ExtensionMenuAction])
    case clipboardSnippets([ExtensionMenuAction])
    case fileOutlines([ExtensionMenuAction])
    case csvTableViewers([ExtensionMenuAction])
    case markdownTools([ExtensionMenuAction])
    case encodingLineEndings([ExtensionMenuAction])
    case focusModes([ExtensionMenuAction])

    var themes: [EditorTheme] { if case let .themes(value) = self { value } else { [] } }
    var textCommands: [TextCommand] { if case let .textCommandsAndFormatters(value, _) = self { value } else { [] } }
    var formatters: [any CodeFormatter] {
        switch self {
        case let .formatters(value), let .textCommandsAndFormatters(_, value): value
        default: []
        }
    }
    var documentBrowsers: [DocumentBrowserExtension] { if case let .documentBrowsers(value) = self { value } else { [] } }
    var clipboards: [ClipboardExtension] { if case let .clipboards(value) = self { value } else { [] } }
    var aiTextTasks: [AITextTask] { if case let .aiTextTasks(value) = self { value } else { [] } }
    var aiSmartSearches: [AISmartSearchExtension] { if case let .aiSmartSearches(value) = self { value } else { [] } }
    var markdownPreviews: [ExtensionMenuAction] { if case let .markdownPreviews(value) = self { value } else { [] } }
    var exportTools: [ExtensionMenuAction] { if case let .exportTools(value) = self { value } else { [] } }
    var documentStatistics: [ExtensionMenuAction] { if case let .documentStatistics(value) = self { value } else { [] } }
    var diffViewers: [ExtensionMenuAction] { if case let .diffViewers(value) = self { value } else { [] } }
    var autoBackups: [ExtensionMenuAction] { if case let .autoBackups(value) = self { value } else { [] } }
    var clipboardSnippets: [ExtensionMenuAction] { if case let .clipboardSnippets(value) = self { value } else { [] } }
    var fileOutlines: [ExtensionMenuAction] { if case let .fileOutlines(value) = self { value } else { [] } }
    var csvTableViewers: [ExtensionMenuAction] { if case let .csvTableViewers(value) = self { value } else { [] } }
    var markdownTools: [ExtensionMenuAction] { if case let .markdownTools(value) = self { value } else { [] } }
    var encodingLineEndings: [ExtensionMenuAction] { if case let .encodingLineEndings(value) = self { value } else { [] } }
    var focusModes: [ExtensionMenuAction] { if case let .focusModes(value) = self { value } else { [] } }
}
