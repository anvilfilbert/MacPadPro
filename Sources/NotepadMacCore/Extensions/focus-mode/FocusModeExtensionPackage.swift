import Foundation

enum FocusModeExtensionPackage {
    static let id = "focus-mode"

    static let catalogEntry = DownloadableExtension(
        id: id,
        title: "Focus / Typewriter Mode",
        description: "Add distraction-free editing with optional current-line focus and typewriter scrolling.",
        version: "1.0.0",
        kind: .focusMode,
        downloadURL: URL(string: "https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/focus-mode/focus-mode.macpadproext")!
    )

    static let actions: [ExtensionMenuAction] = [
        ExtensionMenuAction(id: id, title: "Focus Mode", opensDetachedWindow: false, isResizable: false, isClosable: true)
    ]
}
