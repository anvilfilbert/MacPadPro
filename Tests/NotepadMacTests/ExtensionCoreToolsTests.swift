import XCTest
@testable import NotepadMacCore

final class ExtensionCoreToolsTests: XCTestCase {
    func testConvertsLineEndingsForExtensionTools() {
        XCTAssertEqual(LineEndingConverter.convert("a\nb", to: .windows), "a\r\nb")
        XCTAssertEqual(LineEndingConverter.convert("a\r\nb", to: .unix), "a\nb")
        XCTAssertEqual(LineEndingConverter.convert("a\nb", to: .classicMac), "a\rb")
    }

    func testParsesCSVAndTSVTables() throws {
        let csv = try DelimitedTextTableParser.parse("name,age\nAda,37", delimiter: ",")
        XCTAssertEqual(csv.headers, ["name", "age"])
        XCTAssertEqual(csv.rows, [["Ada", "37"]])

        let tsv = try DelimitedTextTableParser.parse("name\tage\nAda\t37", delimiter: "\t")
        XCTAssertEqual(tsv.headers, ["name", "age"])
        XCTAssertEqual(tsv.rows, [["Ada", "37"]])
    }

    func testRendersBasicMarkdownHTML() {
        let html = MarkdownPreviewRenderer.html(for: "# Title\n\n- Item\n\nText")

        XCTAssertTrue(html.contains("<h1>Title</h1>"))
        XCTAssertTrue(html.contains("<li>Item</li>"))
        XCTAssertTrue(html.contains("<p>Text</p>"))
    }

    func testBuildsFileOutlineFromMarkdownAndCodeSymbols() {
        let items = FileOutlineParser.items(
            for: "# Title\nclass Example\nfunc run() {\n## Details",
            languageID: "swift"
        )

        XCTAssertEqual(items.map(\.title), ["Title", "Example", "run()", "Details"])
        XCTAssertEqual(items.map(\.line), [1, 2, 3, 4])
    }
}
