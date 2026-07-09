import Foundation

public struct DocumentStatistics: Sendable, Equatable {
    public let wordCount: Int
    public let characterCount: Int
    public let lineCount: Int
    public let selectionWordCount: Int
    public let selectionCharacterCount: Int
    public let readingTimeMinutes: Int

    public init(
        wordCount: Int,
        characterCount: Int,
        lineCount: Int,
        selectionWordCount: Int,
        selectionCharacterCount: Int,
        readingTimeMinutes: Int
    ) {
        self.wordCount = wordCount
        self.characterCount = characterCount
        self.lineCount = lineCount
        self.selectionWordCount = selectionWordCount
        self.selectionCharacterCount = selectionCharacterCount
        self.readingTimeMinutes = readingTimeMinutes
    }
}

public enum DocumentStatisticsCalculator {
    public static func statistics(for text: String, selectedText: String, wordsPerMinute: Int) -> DocumentStatistics {
        let words = wordCount(in: text)
        let readingTime = words == 0 ? 0 : max(1, Int(ceil(Double(words) / Double(wordsPerMinute))))

        return DocumentStatistics(
            wordCount: words,
            characterCount: text.count,
            lineCount: lineCount(in: text),
            selectionWordCount: wordCount(in: selectedText),
            selectionCharacterCount: selectedText.count,
            readingTimeMinutes: readingTime
        )
    }

    private static func wordCount(in text: String) -> Int {
        text
            .split { character in
                character.isWhitespace || character.isPunctuation
            }
            .count
    }

    private static func lineCount(in text: String) -> Int {
        guard !text.isEmpty else { return 0 }
        return text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).count
    }
}
