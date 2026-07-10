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
