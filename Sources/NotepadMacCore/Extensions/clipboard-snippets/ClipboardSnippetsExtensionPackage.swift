import Foundation

enum ClipboardSnippetsExtensionPackage {
    static let id = "clipboard-snippets"

    static let catalogEntry = DownloadableExtension(
        id: id,
        title: "Clipboard & Snippets Manager",
        description: "Manage recent clipboard text and pinned named snippets in a detached, resizable, closable panel.",
        version: "1.0.0",
        kind: .clipboardSnippets,
        downloadURL: URL(string: "https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/clipboard-snippets/clipboard-snippets.macpadproext")!
    )

    static let actions: [ExtensionMenuAction] = [
        ExtensionMenuAction(id: id, title: "Clipboard & Snippets", opensDetachedWindow: true, isResizable: true, isClosable: true)
    ]
}
