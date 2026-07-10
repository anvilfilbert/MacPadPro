import Foundation

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
