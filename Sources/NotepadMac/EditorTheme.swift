import AppKit

struct EditorTheme {
    let name: String
    let textColor: NSColor
    let backgroundColor: NSColor
    let insertionPointColor: NSColor
    let statusTextColor: NSColor
    let statusBackgroundColor: NSColor

    static let all: [EditorTheme] = [
        EditorTheme(
            name: "System",
            textColor: .textColor,
            backgroundColor: .textBackgroundColor,
            insertionPointColor: .textColor,
            statusTextColor: .secondaryLabelColor,
            statusBackgroundColor: .windowBackgroundColor
        ),
        EditorTheme(
            name: "Night",
            textColor: NSColor(calibratedRed: 0.86, green: 0.88, blue: 0.90, alpha: 1),
            backgroundColor: NSColor(calibratedRed: 0.10, green: 0.11, blue: 0.12, alpha: 1),
            insertionPointColor: NSColor(calibratedRed: 0.39, green: 0.76, blue: 1.0, alpha: 1),
            statusTextColor: NSColor(calibratedRed: 0.70, green: 0.73, blue: 0.76, alpha: 1),
            statusBackgroundColor: NSColor(calibratedRed: 0.14, green: 0.15, blue: 0.16, alpha: 1)
        ),
        EditorTheme(
            name: "Paper",
            textColor: NSColor(calibratedRed: 0.12, green: 0.12, blue: 0.10, alpha: 1),
            backgroundColor: NSColor(calibratedRed: 0.98, green: 0.96, blue: 0.91, alpha: 1),
            insertionPointColor: NSColor(calibratedRed: 0.15, green: 0.35, blue: 0.75, alpha: 1),
            statusTextColor: NSColor(calibratedRed: 0.40, green: 0.38, blue: 0.32, alpha: 1),
            statusBackgroundColor: NSColor(calibratedRed: 0.93, green: 0.90, blue: 0.83, alpha: 1)
        ),
        EditorTheme(
            name: "Terminal",
            textColor: NSColor(calibratedRed: 0.45, green: 1.0, blue: 0.55, alpha: 1),
            backgroundColor: .black,
            insertionPointColor: NSColor(calibratedRed: 0.45, green: 1.0, blue: 0.55, alpha: 1),
            statusTextColor: NSColor(calibratedRed: 0.35, green: 0.85, blue: 0.45, alpha: 1),
            statusBackgroundColor: NSColor(calibratedWhite: 0.06, alpha: 1)
        )
    ]
}

