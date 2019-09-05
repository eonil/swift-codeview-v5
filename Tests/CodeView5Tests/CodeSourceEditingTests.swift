import XCTest
@testable import CodeView5

final class CodeSourceEditingTests: XCTestCase {
    func testInsertNewLine() {
        var s = CodeSource()
        XCTAssertEqual(s.storage.lines.count, 1)
        XCTAssertEqual(s.storage.lines[0].content, "")
        XCTAssertEqual(s.selectionRange.lowerBound, CodeStoragePosition(line: 0, characterIndex: .zero))
        XCTAssertEqual(s.selectionRange.upperBound, CodeStoragePosition(line: 0, characterIndex: .zero))
        s.replaceCharactersInCurrentSelection(with: "aaa")
        XCTAssertEqual(s.storage.lines.count, 1)
        XCTAssertEqual(s.storage.lines[0].content, "aaa")
        XCTAssertEqual(s.selectionRange.lowerBound, CodeStoragePosition(line: 0, characterIndex: "aaa".endIndex))
        XCTAssertEqual(s.selectionRange.upperBound, CodeStoragePosition(line: 0, characterIndex: "aaa".endIndex))
        s.insertNewLine()
        XCTAssertEqual(s.storage.lines.count, 2)
        XCTAssertEqual(s.storage.lines[0].content, "aaa")
        XCTAssertEqual(s.storage.lines[1].content, "")
        XCTAssertEqual(s.selectionRange.lowerBound, CodeStoragePosition(line: 1, characterIndex: .zero))
        XCTAssertEqual(s.selectionRange.upperBound, CodeStoragePosition(line: 1, characterIndex: .zero))
        s.replaceCharactersInCurrentSelection(with: "bbb")
        XCTAssertEqual(s.storage.lines.count, 2)
        XCTAssertEqual(s.storage.lines[0].content, "aaa")
        XCTAssertEqual(s.storage.lines[1].content, "bbb")
        XCTAssertEqual(s.selectionRange.lowerBound, CodeStoragePosition(line: 1, characterIndex: "bbb".endIndex))
        XCTAssertEqual(s.selectionRange.upperBound, CodeStoragePosition(line: 1, characterIndex: "bbb".endIndex))
        s.selectAll()
        s.replaceCharactersInCurrentSelection(with: "")
        XCTAssertEqual(s.storage.lines.count, 1)
        XCTAssertEqual(s.storage.lines[0].content, "")
        XCTAssertEqual(s.selectionRange.lowerBound, CodeStoragePosition(line: 0, characterIndex: .zero))
        XCTAssertEqual(s.selectionRange.upperBound, CodeStoragePosition(line: 0, characterIndex: .zero))
    }
    func testDeleteSecondLine() {
        var s = CodeSource()
        s.replaceCharactersInCurrentSelection(with: "aaa")
        s.insertNewLine()
        s.replaceCharactersInCurrentSelection(with: "bbb")
        XCTAssertEqual(s.storage.lines.count, 2)
        XCTAssertEqual(s.storage.lines[0].content, "aaa")
        XCTAssertEqual(s.storage.lines[1].content, "bbb")
        XCTAssertEqual(s.caretPosition, CodeStoragePosition(line: 1, characterIndex: "bbb".endIndex))
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
