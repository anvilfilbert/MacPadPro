import Foundation

enum DiffViewerExtensionPackage {
    static let id = "diff-viewer"

    static let catalogEntry = DownloadableExtension(
        id: id,
        title: "Diff Viewer",
        description: "Compare the current document against clipboard text or another file in a detached diff window.",
        version: "1.0.0",
        kind: .diffViewer,
        downloadURL: URL(string: "https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/diff-viewer/diff-viewer.macpadproext")!
    )

    static let actions: [ExtensionMenuAction] = [
        ExtensionMenuAction(id: id, title: "Compare...", opensDetachedWindow: true, isResizable: true, isClosable: true)
    ]
}
