import Foundation

enum MarkdownToolsExtensionPackage {
    static let id = "markdown-tools"

    static let catalogEntry = DownloadableExtension(
        id: id,
        title: "Markdown Tools",
        description: "Add Markdown editing commands for checkboxes, tables, lists, and ordered-list renumbering.",
        version: "1.0.0",
        kind: .markdownTools,
        downloadURL: URL(string: "https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/markdown-tools/markdown-tools.macpadproext")!
    )

    static let actions: [ExtensionMenuAction] = [
        ExtensionMenuAction(id: id, title: "Tools", opensDetachedWindow: false, isResizable: false, isClosable: true)
    ]
}
