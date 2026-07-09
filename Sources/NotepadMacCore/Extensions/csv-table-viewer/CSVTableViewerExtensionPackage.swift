import Foundation

enum CSVTableViewerExtensionPackage {
    static let id = "csv-table-viewer"

    static let catalogEntry = DownloadableExtension(
        id: id,
        title: "CSV Table Viewer",
        description: "Preview CSV or TSV text as a readable table without changing the original plain text.",
        version: "1.0.0",
        kind: .csvTableViewer,
        downloadURL: URL(string: "https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/csv-table-viewer/csv-table-viewer.macpadproext")!
    )

    static let actions: [ExtensionMenuAction] = [
        ExtensionMenuAction(id: id, title: "Table Preview", opensDetachedWindow: true, isResizable: true, isClosable: true)
    ]
}
