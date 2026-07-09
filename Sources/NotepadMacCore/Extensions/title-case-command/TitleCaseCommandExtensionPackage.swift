import Foundation

enum TitleCaseCommandExtensionPackage {
    static let id = "title-case-command"

    static let catalogEntry = DownloadableExtension(
        id: id,
        title: "Title Case Command",
        description: "Convert selected text to title case with a JavaScript plugin command.",
        version: "1.0.0",
        kind: .textCommand,
        author: "MacPad Pro Examples",
        permissions: [.readSelectedText, .editSelectedText],
        downloadURL: URL(string: "https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/title-case-command/title-case-command.macpadproext")!
    )
}
