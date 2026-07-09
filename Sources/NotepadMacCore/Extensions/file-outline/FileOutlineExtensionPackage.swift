import Foundation

enum FileOutlineExtensionPackage {
    static let id = "file-outline"

    static let catalogEntry = DownloadableExtension(
        id: id,
        title: "File Outline",
        description: "Show Markdown headings and simple code symbols in a detached, resizable, closable navigation panel.",
        version: "1.0.0",
        kind: .fileOutline,
        downloadURL: URL(string: "https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/file-outline/file-outline.macpadproext")!
    )

    static let actions: [ExtensionMenuAction] = [
        ExtensionMenuAction(id: id, title: "File Outline", opensDetachedWindow: true, isResizable: true, isClosable: true)
    ]
}
