import XCTest
@testable import NotepadMacCore

final class MarkdownToolsTests: XCTestCase {
    func testTogglesMarkdownCheckboxes() throws {
        XCTAssertEqual(try MarkdownEditingTools.toggleCheckbox("- [ ] task"), "- [x] task")
        XCTAssertEqual(try MarkdownEditingTools.toggleCheckbox("- [x] task"), "- [ ] task")
        XCTAssertEqual(try MarkdownEditingTools.toggleCheckbox("task"), "- [ ] task")
    }

    func testInsertsMarkdownTable() {
        XCTAssertEqual(
            MarkdownEditingTools.insertTable(),
            """
            | Column 1 | Column 2 |
            | --- | --- |
            |  |  |
            """
        )
    }

    func testFormatsUnorderedList() {
        XCTAssertEqual(
            MarkdownEditingTools.formatUnorderedList("one\n- two\n  three"),
            "- one\n- two\n- three"
        )
    }

    func testRenumbersOrderedList() {
        XCTAssertEqual(
            MarkdownEditingTools.renumberOrderedList("5. First\n3. Second\nPlain"),
            "1. First\n2. Second\nPlain"
        )
    }
}
