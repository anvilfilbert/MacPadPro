import Foundation

enum DocumentStatisticsExtensionPackage {
    static let id = "document-statistics"

    static let catalogEntry = DownloadableExtension(
        id: id,
        title: "Document Statistics",
        description: "Show word, character, line, selection, and reading-time statistics for the current document.",
        version: "1.0.0",
        kind: .documentStatistics,
        downloadURL: URL(string: "https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/document-statistics/document-statistics.macpadproext")!
    )

    static let actions: [ExtensionMenuAction] = [
        ExtensionMenuAction(id: id, title: "Document Statistics", opensDetachedWindow: true, isResizable: true, isClosable: true)
    ]
}
