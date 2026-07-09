import XCTest
@testable import NotepadMacCore

final class DocumentStatisticsTests: XCTestCase {
    func testCalculatesDocumentAndSelectionStatistics() {
        let statistics = DocumentStatisticsCalculator.statistics(
            for: "One two three\nFour",
            selectedText: "two three",
            wordsPerMinute: 200
        )

        XCTAssertEqual(statistics.wordCount, 4)
        XCTAssertEqual(statistics.characterCount, 18)
        XCTAssertEqual(statistics.lineCount, 2)
        XCTAssertEqual(statistics.selectionWordCount, 2)
        XCTAssertEqual(statistics.selectionCharacterCount, 9)
        XCTAssertEqual(statistics.readingTimeMinutes, 1)
    }

    func testEmptyDocumentHasZeroLinesAndReadingTime() {
        let statistics = DocumentStatisticsCalculator.statistics(
            for: "",
            selectedText: "",
            wordsPerMinute: 200
        )

        XCTAssertEqual(statistics.wordCount, 0)
        XCTAssertEqual(statistics.characterCount, 0)
        XCTAssertEqual(statistics.lineCount, 0)
        XCTAssertEqual(statistics.readingTimeMinutes, 0)
    }
}
