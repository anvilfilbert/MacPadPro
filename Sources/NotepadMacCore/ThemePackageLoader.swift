import AppKit
import Foundation

public enum ThemePackageError: LocalizedError, Equatable {
    case emptyThemeList(file: String)
    case duplicateThemeID(id: String)
    case invalidColorComponent(themeID: String, colorName: String, componentName: String, value: Double)

    public var errorDescription: String? {
        switch self {
        case let .emptyThemeList(file):
            "Theme package '\(file)' does not contain any themes."
        case let .duplicateThemeID(id):
            "Theme package contains duplicate theme id '\(id)'."
        case let .invalidColorComponent(themeID, colorName, componentName, value):
            "Theme '\(themeID)' has invalid \(colorName).\(componentName) value \(value). Expected a value between 0 and 1."
        }
    }
}

public struct ExtensionThemeFile: Codable, Sendable, Equatable {
    public let themes: [ExtensionThemeDefinition]

    public init(themes: [ExtensionThemeDefinition]) {
        self.themes = themes
    }
}

public struct ExtensionThemeDefinition: Codable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let textColor: ExtensionThemeColor
    public let backgroundColor: ExtensionThemeColor
    public let insertionPointColor: ExtensionThemeColor
    public let statusTextColor: ExtensionThemeColor
    public let statusBackgroundColor: ExtensionThemeColor

    public init(
        id: String,
        name: String,
        textColor: ExtensionThemeColor,
        backgroundColor: ExtensionThemeColor,
        insertionPointColor: ExtensionThemeColor,
        statusTextColor: ExtensionThemeColor,
        statusBackgroundColor: ExtensionThemeColor
    ) {
        self.id = id
        self.name = name
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.insertionPointColor = insertionPointColor
        self.statusTextColor = statusTextColor
        self.statusBackgroundColor = statusBackgroundColor
    }
}

public struct ExtensionThemeColor: Codable, Sendable, Equatable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

public struct ThemePackageLoader: Sendable {
    public init() {}

    public func loadThemes(from url: URL) throws -> [EditorTheme] {
        let data = try Data(contentsOf: url)
        let themeFile = try JSONDecoder().decode(ExtensionThemeFile.self, from: data)
        return try themes(from: themeFile, fileName: url.lastPathComponent)
    }

    public func themes(from themeFile: ExtensionThemeFile, fileName: String) throws -> [EditorTheme] {
        guard !themeFile.themes.isEmpty else {
            throw ThemePackageError.emptyThemeList(file: fileName)
        }

        var seenIDs = Set<String>()
        return try themeFile.themes.map { definition in
            if seenIDs.contains(definition.id) {
                throw ThemePackageError.duplicateThemeID(id: definition.id)
            }
            seenIDs.insert(definition.id)
            return try EditorTheme(
                id: definition.id,
                name: definition.name,
                textColor: nsColor(from: definition.textColor, themeID: definition.id, colorName: "textColor"),
                backgroundColor: nsColor(from: definition.backgroundColor, themeID: definition.id, colorName: "backgroundColor"),
                insertionPointColor: nsColor(from: definition.insertionPointColor, themeID: definition.id, colorName: "insertionPointColor"),
                statusTextColor: nsColor(from: definition.statusTextColor, themeID: definition.id, colorName: "statusTextColor"),
                statusBackgroundColor: nsColor(from: definition.statusBackgroundColor, themeID: definition.id, colorName: "statusBackgroundColor")
            )
        }
    }

    private func nsColor(from color: ExtensionThemeColor, themeID: String, colorName: String) throws -> NSColor {
        try validate(color.red, componentName: "red", themeID: themeID, colorName: colorName)
        try validate(color.green, componentName: "green", themeID: themeID, colorName: colorName)
        try validate(color.blue, componentName: "blue", themeID: themeID, colorName: colorName)
        try validate(color.alpha, componentName: "alpha", themeID: themeID, colorName: colorName)
        return NSColor(
            calibratedRed: CGFloat(color.red),
            green: CGFloat(color.green),
            blue: CGFloat(color.blue),
            alpha: CGFloat(color.alpha)
        )
    }

    private func validate(_ value: Double, componentName: String, themeID: String, colorName: String) throws {
        guard value >= 0, value <= 1 else {
            throw ThemePackageError.invalidColorComponent(
                themeID: themeID,
                colorName: colorName,
                componentName: componentName,
                value: value
            )
        }
    }
}
