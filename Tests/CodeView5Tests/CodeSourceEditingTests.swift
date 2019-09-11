import XCTest
@testable import CodeView5

final class CodeSourceEditingTests: XCTestCase {
    func testInsertNewLine() {
        var s = CodeSource()
        XCTAssertEqual(s.storage.lines.count, 1)
        XCTAssertEqual(s.storage.lines[0].content, "")
        XCTAssertEqual(s.selectionRange.lowerBound, s.testPosition(line: 0, column: 0).csp)
        XCTAssertEqual(s.selectionRange.upperBound, s.testPosition(line: 0, column: 0).csp)
        s.replaceCharactersInCurrentSelection(with: "aaa")
        XCTAssertEqual(s.storage.lines.count, 1)
        XCTAssertEqual(s.storage.lines[0].content, "aaa")
        XCTAssertEqual(s.selectionRange.lowerBound, s.testPosition(line: 0, column: 3).csp)
        XCTAssertEqual(s.selectionRange.upperBound, s.testPosition(line: 0, column: 3).csp)
        s.insertNewLine()
        XCTAssertEqual(s.storage.lines.count, 2)
        XCTAssertEqual(s.storage.lines[0].content, "aaa")
        XCTAssertEqual(s.storage.lines[1].content, "")
        XCTAssertEqual(s.selectionRange.lowerBound, s.testPosition(line: 1, column: 0).csp)
        XCTAssertEqual(s.selectionRange.upperBound, s.testPosition(line: 1, column: 0).csp)
        s.replaceCharactersInCurrentSelection(with: "bbb")
        XCTAssertEqual(s.storage.lines.count, 2)
        XCTAssertEqual(s.storage.lines[0].content, "aaa")
        XCTAssertEqual(s.storage.lines[1].content, "bbb")
        XCTAssertEqual(s.selectionRange.lowerBound, s.testPosition(line: 1, column: 3).csp)
        XCTAssertEqual(s.selectionRange.upperBound, s.testPosition(line: 1, column: 3).csp)
        s.selectAll()
        s.replaceCharactersInCurrentSelection(with: "")
        XCTAssertEqual(s.storage.lines.count, 1)
        XCTAssertEqual(s.storage.lines[0].content, "")
        XCTAssertEqual(s.selectionRange.lowerBound, s.testPosition(line: 0, column: 0).csp)
        XCTAssertEqual(s.selectionRange.upperBound, s.testPosition(line: 0, column: 0).csp)
    }
    func testDeleteSecondLine() {
        var s = CodeSource()
        s.replaceCharactersInCurrentSelection(with: "aaa")
        s.insertNewLine()
        s.replaceCharactersInCurrentSelection(with: "bbb")
        XCTAssertEqual(s.storage.lines.count, 2)
        XCTAssertEqual(s.storage.lines[0].content, "aaa")
        XCTAssertEqual(s.storage.lines[1].content, "bbb")
        XCTAssertEqual(s.caretPosition, s.testPosition(line: 1, column: 3).csp)
        s.deleteBackward()
        XCTAssertEqual(s.storage.lines.count, 2)
        XCTAssertEqual(s.storage.lines[0].content, "aaa")
        XCTAssertEqual(s.storage.lines[1].content, "bb")
        s.deleteBackward()
        XCTAssertEqual(s.storage.lines.count, 2)
        XCTAssertEqual(s.storage.lines[0].content, "aaa")
        XCTAssertEqual(s.storage.lines[1].content, "b")
        s.deleteBackward()
        XCTAssertEqual(s.storage.lines.count, 2)
        XCTAssertEqual(s.storage.lines[0].content, "aaa")
        XCTAssertEqual(s.storage.lines[1].content, "")
        s.deleteBackward()
        XCTAssertEqual(s.storage.lines.count, 1)
        XCTAssertEqual(s.storage.lines[0].content, "aaa")
    }
    static var allTests = [
        ("testInsertNewLine", testInsertNewLine),
        ("testDeleteSecondLine", testDeleteSecondLine),
    ]
}
