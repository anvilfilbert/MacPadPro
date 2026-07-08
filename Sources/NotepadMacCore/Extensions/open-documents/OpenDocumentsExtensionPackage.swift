import Foundation

enum OpenDocumentsExtensionPackage {
    static let id = "open-documents"

    static let catalogEntry = DownloadableExtension(
        id: id,
        title: "Document Browser",
        description: "Browse open documents in a detached, resizable, closable window.",
        version: "1.0.0",
        kind: .documentBrowser,
        downloadURL: URL(string: "https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/open-documents/open-documents.macpadproext")!
    )

    static let documentBrowsers: [DocumentBrowserExtension] = [
        DocumentBrowserExtension(
            id: id,
            title: "Document Browser",
            opensDetachedWindow: true,
            isResizable: true,
            isClosable: true
        )
    ]
}
