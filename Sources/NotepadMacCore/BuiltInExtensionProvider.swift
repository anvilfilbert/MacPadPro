import AppKit

enum BuiltInExtensions {
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
