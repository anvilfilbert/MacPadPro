import Foundation

enum MarkdownPreviewExtensionPackage {
    static let id = "markdown-preview"

    static let catalogEntry = DownloadableExtension(
        id: id,
        title: "Markdown Preview",
        description: "Preview Markdown from the current document or selection in a detached, resizable, closable window.",
        version: "1.0.0",
        kind: .markdownPreview,
        downloadURL: URL(string: "https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/markdown-preview/markdown-preview.macpadproext")!
    )

    static let actions: [ExtensionMenuAction] = [
        ExtensionMenuAction(id: id, title: "Preview", opensDetachedWindow: true, isResizable: true, isClosable: true)
    ]
}
