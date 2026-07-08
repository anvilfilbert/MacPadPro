import AppKit
import Foundation

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

public enum ExtensionKind: String, Codable, Sendable {
    case documentBrowser
    case theme
    case language
    case formatter
    case textCommand
    case clipboard
    case aiTextTask
    case aiSmartSearch
}

public struct DownloadableExtension: Codable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let description: String
    public let version: String
    public let kind: ExtensionKind
    public let downloadURL: URL

    public init(id: String, title: String, description: String, version: String, kind: ExtensionKind, downloadURL: URL) {
        self.id = id
        self.title = title
        self.description = description
        self.version = version
        self.kind = kind
        self.downloadURL = downloadURL
    }
}

public struct ExtensionPackageManifest: Codable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let description: String
    public let version: String
    public let kind: ExtensionKind

    public init(id: String, title: String, description: String, version: String, kind: ExtensionKind) {
        self.id = id
        self.title = title
        self.description = description
        self.version = version
        self.kind = kind
    }
}

public enum ExtensionPackageDownloadError: LocalizedError, Equatable {
    case packageDoesNotMatchCatalog(expectedID: String, actualID: String)

    public var errorDescription: String? {
        switch self {
        case let .packageDoesNotMatchCatalog(expectedID, actualID):
            "Downloaded package id '\(actualID)' does not match catalog extension id '\(expectedID)'."
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
        let packageData = try Data(contentsOf: packageURL(for: extensionItem.id))
        let manifest = try JSONDecoder().decode(ExtensionPackageManifest.self, from: packageData)
        try manifest.validate(matches: extensionItem)
    }
}

private extension ExtensionPackageManifest {
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

    public static let `default` = ExtensionCatalog(extensions: BuiltInExtensions.downloadableExtensions)

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
        let destinationURL = ExtensionPackageStore(directory: directory).packageURL(for: extensionItem.id)
        try packageData.write(to: destinationURL, options: .atomic)
        return destinationURL
    }
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

    public static let `default` = loaded(installedExtensions: .bundledDefault)

    public static func loaded(installedExtensions: InstalledExtensions) -> ExtensionRegistry {
        let themes = BuiltInExtensions.systemThemes
            + (installedExtensions.isActive(ProThemesExtensionPackage.id) ? ProThemesExtensionPackage.themes : [])
        let formatters = (installedExtensions.isActive(JSONFormatterExtensionPackage.id) ? JSONFormatterExtensionPackage.formatters : [])
            + (installedExtensions.isActive(CFamilyFormatterExtensionPackage.id) ? CFamilyFormatterExtensionPackage.formatters : [])
        let textCommands = BuiltInExtensions.coreTextCommands
            + (installedExtensions.isActive(JSONFormatterExtensionPackage.id) ? JSONFormatterExtensionPackage.textCommands : [])
        let documentBrowsers = installedExtensions.isActive(OpenDocumentsExtensionPackage.id) ? OpenDocumentsExtensionPackage.documentBrowsers : []
        let clipboards = installedExtensions.isActive(ClipboardSlotsExtensionPackage.id) ? ClipboardSlotsExtensionPackage.clipboards : []
        let aiTextTasks =
            (installedExtensions.isActive(AISummarizerExtensionPackage.id) ? AISummarizerExtensionPackage.textTasks : [])
            + (installedExtensions.isActive(AICodeExplainerExtensionPackage.id) ? AICodeExplainerExtensionPackage.textTasks : [])
            + (installedExtensions.isActive(AICodeRefactorExtensionPackage.id) ? AICodeRefactorExtensionPackage.textTasks : [])
            + (installedExtensions.isActive(AIMeetingNotesExtensionPackage.id) ? AIMeetingNotesExtensionPackage.textTasks : [])
        let aiSmartSearches = installedExtensions.isActive(AISmartSearchExtensionPackage.id) ? AISmartSearchExtensionPackage.smartSearches : []

        return ExtensionRegistry(
            themes: themes,
            languages: BuiltInExtensions.languages,
            textCommands: textCommands,
            formatters: formatters,
            documentBrowsers: documentBrowsers,
            clipboards: clipboards,
            aiTextTasks: aiTextTasks,
            aiSmartSearches: aiSmartSearches
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

    static let downloadableExtensions: [DownloadableExtension] = [
        OpenDocumentsExtensionPackage.catalogEntry,
        JSONFormatterExtensionPackage.catalogEntry,
        CFamilyFormatterExtensionPackage.catalogEntry,
        ClipboardSlotsExtensionPackage.catalogEntry,
        AISummarizerExtensionPackage.catalogEntry,
        AICodeExplainerExtensionPackage.catalogEntry,
        AICodeRefactorExtensionPackage.catalogEntry,
        AIMeetingNotesExtensionPackage.catalogEntry,
        AISmartSearchExtensionPackage.catalogEntry,
        ProThemesExtensionPackage.catalogEntry
    ]
}
