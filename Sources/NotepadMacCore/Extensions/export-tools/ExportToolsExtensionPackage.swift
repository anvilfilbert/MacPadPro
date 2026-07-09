import Foundation

enum ExportToolsExtensionPackage {
    static let id = "export-tools"

    static let catalogEntry = DownloadableExtension(
        id: id,
        title: "Export Tools",
        description: "Export the current document as PDF, HTML, Markdown, or RTF where practical.",
        version: "1.0.0",
        kind: .exportTools,
        downloadURL: URL(string: "https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/export-tools/export-tools.macpadproext")!
    )

    static let actions: [ExtensionMenuAction] = [
        ExtensionMenuAction(id: id, title: "Export As...", opensDetachedWindow: false, isResizable: false, isClosable: true)
    ]
}
