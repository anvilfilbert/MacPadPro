import Foundation

enum EncodingLineEndingsExtensionPackage {
    static let id = "encoding-line-endings"

    static let catalogEntry = DownloadableExtension(
        id: id,
        title: "Encoding / Line Ending Tools",
        description: "Show current text encoding and convert line endings between Unix, Windows, and classic Mac styles.",
        version: "1.0.0",
        kind: .encodingLineEndings,
        downloadURL: URL(string: "https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/encoding-line-endings/encoding-line-endings.macpadproext")!
    )

    static let actions: [ExtensionMenuAction] = [
        ExtensionMenuAction(id: id, title: "Encoding & Line Endings", opensDetachedWindow: false, isResizable: false, isClosable: true)
    ]
}
