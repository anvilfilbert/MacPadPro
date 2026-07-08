import AppKit
import Foundation

enum ProThemesExtensionPackage {
    static let id = "pro-themes"

    static let catalogEntry = DownloadableExtension(
        id: id,
        title: "Pro Themes",
        description: "Add Night, Paper, and Terminal editor themes.",
        version: "1.0.0",
        kind: .theme,
        downloadURL: URL(string: "https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/pro-themes/pro-themes.macpadproext")!
    )

    static let themes: [EditorTheme] = [
        EditorTheme(
            id: "night",
            name: "Night",
            textColor: NSColor(calibratedRed: 0.86, green: 0.88, blue: 0.90, alpha: 1),
            backgroundColor: NSColor(calibratedRed: 0.10, green: 0.11, blue: 0.12, alpha: 1),
            insertionPointColor: NSColor(calibratedRed: 0.39, green: 0.76, blue: 1.0, alpha: 1),
            statusTextColor: NSColor(calibratedRed: 0.70, green: 0.73, blue: 0.76, alpha: 1),
            statusBackgroundColor: NSColor(calibratedRed: 0.14, green: 0.15, blue: 0.16, alpha: 1)
        ),
        EditorTheme(
            id: "paper",
            name: "Paper",
            textColor: NSColor(calibratedRed: 0.12, green: 0.12, blue: 0.10, alpha: 1),
            backgroundColor: NSColor(calibratedRed: 0.98, green: 0.96, blue: 0.91, alpha: 1),
            insertionPointColor: NSColor(calibratedRed: 0.15, green: 0.35, blue: 0.75, alpha: 1),
            statusTextColor: NSColor(calibratedRed: 0.40, green: 0.38, blue: 0.32, alpha: 1),
            statusBackgroundColor: NSColor(calibratedRed: 0.93, green: 0.90, blue: 0.83, alpha: 1)
        ),
        EditorTheme(
            id: "terminal",
            name: "Terminal",
            textColor: NSColor(calibratedRed: 0.45, green: 1.0, blue: 0.55, alpha: 1),
            backgroundColor: .black,
            insertionPointColor: NSColor(calibratedRed: 0.45, green: 1.0, blue: 0.55, alpha: 1),
            statusTextColor: NSColor(calibratedRed: 0.35, green: 0.85, blue: 0.45, alpha: 1),
            statusBackgroundColor: NSColor(calibratedWhite: 0.06, alpha: 1)
        )
    ]
}
