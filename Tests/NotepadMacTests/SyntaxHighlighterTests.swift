import XCTest
@testable import NotepadMacCore

final class SyntaxHighlighterTests: XCTestCase {
    func testPhpHighlighterFindsDirectiveKeywordsVariablesStringsAndComments() {
        let text = """
        <?php
        /**
         * Analyze DCA
         */
        class DCAAnalyzer {
            private float $dcaAmount;

            public function simulateDCA(): array {
                // Initial investment
                return ['interval' => 'monthly'];
            }
        }
        """

        let tokens = SyntaxHighlighter().tokens(in: text, languageID: "php")

        XCTAssertTrue(tokenTexts(kind: .directive, in: text, tokens: tokens).contains("<?php"))
        XCTAssertTrue(tokenTexts(kind: .keyword, in: text, tokens: tokens).contains("class"))
        XCTAssertTrue(tokenTexts(kind: .keyword, in: text, tokens: tokens).contains("private"))
        XCTAssertTrue(tokenTexts(kind: .keyword, in: text, tokens: tokens).contains("function"))
        XCTAssertTrue(tokenTexts(kind: .keyword, in: text, tokens: tokens).contains("return"))
        XCTAssertTrue(tokenTexts(kind: .variable, in: text, tokens: tokens).contains("$dcaAmount"))
        XCTAssertTrue(tokenTexts(kind: .stringLiteral, in: text, tokens: tokens).contains("'monthly'"))
        XCTAssertTrue(tokenTexts(kind: .comment, in: text, tokens: tokens).contains { $0.contains("Analyze DCA") })
        XCTAssertTrue(tokenTexts(kind: .comment, in: text, tokens: tokens).contains("// Initial investment"))
    }

    func testCppHighlighterFindsKeywordsStringsNumbersAndComments() {
        let text = """
        class DCAAnalyzer {
        public:
            int simulate() {
                // Initial investment
                return 12;
            }
        };
        """

        let tokens = SyntaxHighlighter().tokens(in: text, languageID: "cpp")

        XCTAssertTrue(tokenTexts(kind: .keyword, in: text, tokens: tokens).contains("class"))
        XCTAssertTrue(tokenTexts(kind: .keyword, in: text, tokens: tokens).contains("public"))
        XCTAssertTrue(tokenTexts(kind: .keyword, in: text, tokens: tokens).contains("int"))
        XCTAssertTrue(tokenTexts(kind: .keyword, in: text, tokens: tokens).contains("return"))
        XCTAssertTrue(tokenTexts(kind: .numberLiteral, in: text, tokens: tokens).contains("12"))
        XCTAssertTrue(tokenTexts(kind: .comment, in: text, tokens: tokens).contains("// Initial investment"))
    }

    func testPlainTextHighlighterDoesNotColorWordsThatLookLikeCode() {
        let text = "class private function return $amount"

        let tokens = SyntaxHighlighter().tokens(in: text, languageID: "plain-text")

        XCTAssertTrue(tokens.isEmpty)
    }

    private func tokenTexts(kind: SyntaxHighlightKind, in text: String, tokens: [SyntaxHighlightToken]) -> [String] {
        let nsText = text as NSString
        return tokens
            .filter { $0.kind == kind }
            .map { nsText.substring(with: $0.range) }
    }
}
