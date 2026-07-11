import Foundation

enum ProThemesExtensionPackage {
    static let id = "pro-themes"

    static let catalogEntry = DownloadableExtension(
        id: id,
        title: "Pro Themes",
        description: "Add Night, Paper, Terminal, Ocean, Forest, Sunset, Lavender, and High Contrast editor themes.",
        version: "1.0.1",
        kind: .theme,
        downloadURL: URL(string: "https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/pro-themes/pro-themes.macpadproext")!
    )

    static let themeResourceFile = "themes.json"
}
