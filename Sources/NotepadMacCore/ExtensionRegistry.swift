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
}

public struct DownloadableExtension: Codable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let version: String
    public let kind: ExtensionKind
    public let downloadURL: URL

    public init(id: String, title: String, version: String, kind: ExtensionKind, downloadURL: URL) {
        self.id = id
        self.title = title
        self.version = version
        self.kind = kind
        self.downloadURL = downloadURL
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
}

public struct InstalledExtensions: Codable, Sendable, Equatable {
    public private(set) var installedIDs: Set<String>

    public static let bundledDefault = InstalledExtensions(installedIDs: BuiltInExtensions.defaultInstalledExtensionIDs)

    public init(installedIDs: Set<String>) {
        self.installedIDs = installedIDs
    }

    public func isInstalled(_ id: String) -> Bool {
        installedIDs.contains(id)
    }

    public mutating func load(_ id: String) {
        installedIDs.insert(id)
    }

    public mutating func delete(_ id: String) {
        installedIDs.remove(id)
    }
}

public struct ExtensionRegistry: Sendable {
    public let themes: [EditorTheme]
    public let languages: [LanguageDefinition]
    public let textCommands: [TextCommand]
    public let formatters: [any CodeFormatter]
    public let documentBrowsers: [DocumentBrowserExtension]

    public static let `default` = loaded(installedExtensions: .bundledDefault)

    public static func loaded(installedExtensions: InstalledExtensions) -> ExtensionRegistry {
        let themes = BuiltInExtensions.systemThemes
            + (installedExtensions.isInstalled("pro-themes") ? BuiltInExtensions.proThemes : [])
        let formatters = installedExtensions.isInstalled("json-formatter") ? BuiltInExtensions.formatters : []
        let textCommands = BuiltInExtensions.coreTextCommands
            + (installedExtensions.isInstalled("json-formatter") ? BuiltInExtensions.formatterTextCommands : [])
        let documentBrowsers = installedExtensions.isInstalled("open-documents") ? BuiltInExtensions.documentBrowsers : []

        return ExtensionRegistry(
            themes: themes,
            languages: BuiltInExtensions.languages,
            textCommands: textCommands,
            formatters: formatters,
            documentBrowsers: documentBrowsers
        )
    }

    public func detectLanguage(for fileURL: URL?, text: String) -> String {
        if let fileURL {
            let ext = fileURL.pathExtension.lowercased()
            if let language = languages.first(where: { $0.fileExtensions.contains(ext) }) {
                return language.name
            }
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("#!/"),
           let firstLine = trimmed.split(separator: "\n", maxSplits: 1).first {
            let line = firstLine.lowercased()
            if let language = languages.first(where: { definition in
                definition.shebangHints.contains(where: line.contains)
            }) {
                return language.name
            }
            return "Script"
        }
        if looksLikeJSON(trimmed) {
            return "JSON"
        }
        if trimmed.hasPrefix("<!doctype html") || trimmed.hasPrefix("<html") {
            return "HTML"
        }
        return "Plain Text"
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
    static let defaultInstalledExtensionIDs: Set<String> = [
        "open-documents",
        "json-formatter",
        "pro-themes"
    ]

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

    static let proThemes: [EditorTheme] = [
        EditorTheme(
            id: "night",
            name: "Night",
            textColor: NSColor(calibratedRed: 0.86, green: 0.88, blue: 0.90, alpha: 1),
            backgroundColor: NSColor(calibratedRed: 0.10, green: 0.11, blue: 0.12, alpha: 1),
            insertionPointColor: NSColor(calibratedRed: 0.39, green: 0.76, blue: 1.0, alpha: 1),
            statusTextColor: NSColor(calibratedRed: 0.70, green: 0.73, blue: 0.76, alpha: 1),
            statusBackgroundColor: NSColor(calibratedRed: 0.14, green: 0.15, blue: 0.16, alpha: 1)
        ),
        EditorTheme(
            id: "paper",
            name: "Paper",
            textColor: NSColor(calibratedRed: 0.12, green: 0.12, blue: 0.10, alpha: 1),
            backgroundColor: NSColor(calibratedRed: 0.98, green: 0.96, blue: 0.91, alpha: 1),
            insertionPointColor: NSColor(calibratedRed: 0.15, green: 0.35, blue: 0.75, alpha: 1),
            statusTextColor: NSColor(calibratedRed: 0.40, green: 0.38, blue: 0.32, alpha: 1),
            statusBackgroundColor: NSColor(calibratedRed: 0.93, green: 0.90, blue: 0.83, alpha: 1)
        ),
        EditorTheme(
            id: "terminal",
            name: "Terminal",
            textColor: NSColor(calibratedRed: 0.45, green: 1.0, blue: 0.55, alpha: 1),
            backgroundColor: .black,
            insertionPointColor: NSColor(calibratedRed: 0.45, green: 1.0, blue: 0.55, alpha: 1),
            statusTextColor: NSColor(calibratedRed: 0.35, green: 0.85, blue: 0.45, alpha: 1),
            statusBackgroundColor: NSColor(calibratedWhite: 0.06, alpha: 1)
        )
    ]

    static let themes: [EditorTheme] = systemThemes + proThemes

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

    static let formatterTextCommands: [TextCommand] = [
        TextCommand(id: "pretty-print-json", title: "Pretty Print JSON") { text in
            try JSONCodeFormatter().format(text)
        }
    ]

    static let textCommands: [TextCommand] = coreTextCommands + formatterTextCommands

    static let formatters: [any CodeFormatter] = [
        JSONCodeFormatter()
    ]

    static let documentBrowsers: [DocumentBrowserExtension] = [
        DocumentBrowserExtension(
            id: "open-documents",
            title: "Document Browser",
            opensDetachedWindow: true,
            isResizable: true,
            isClosable: true
        )
    ]

    static let downloadableExtensions: [DownloadableExtension] = [
        DownloadableExtension(
            id: "open-documents",
            title: "Document Browser",
            version: "1.0.0",
            kind: .documentBrowser,
            downloadURL: URL(string: "https://github.com/anvilfilbert/MacPadPro/releases/download/extensions/open-documents.macpadproext")!
        ),
        DownloadableExtension(
            id: "json-formatter",
            title: "JSON Formatter",
            version: "1.0.0",
            kind: .formatter,
            downloadURL: URL(string: "https://github.com/anvilfilbert/MacPadPro/releases/download/extensions/json-formatter.macpadproext")!
        ),
        DownloadableExtension(
            id: "pro-themes",
            title: "Pro Themes",
            version: "1.0.0",
            kind: .theme,
            downloadURL: URL(string: "https://github.com/anvilfilbert/MacPadPro/releases/download/extensions/pro-themes.macpadproext")!
        )
    ]
}

public struct JSONCodeFormatter: CodeFormatter {
    public let id = "json"
    public let name = "JSON"
    public let supportedLanguageIDs: Set<String> = ["json"]

    public init() {}

    public func format(_ text: String) throws -> String {
        let data = Data(text.utf8)
        let object = try JSONSerialization.jsonObject(with: data)
        let prettyData = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
        return String(data: prettyData, encoding: .utf8) ?? text
    }
}
