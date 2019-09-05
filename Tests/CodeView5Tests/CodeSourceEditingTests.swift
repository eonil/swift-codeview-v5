import XCTest
@testable import CodeView5

final class CodeSourceEditingTests: XCTestCase {
    func testInsertNewLine() {
        var s = CodeSource()
        XCTAssertEqual(s.storage.lines.count, 1)
        XCTAssertEqual(s.storage.lines[0].utf8Characters, "")
        XCTAssertEqual(s.storageSelection.range.lowerBound, CodeStoragePosition(line: 0, characterIndex: .zero))
        XCTAssertEqual(s.storageSelection.range.upperBound, CodeStoragePosition(line: 0, characterIndex: .zero))
        s.replaceCharactersInCurrentSelection(with: "aaa", selection: .atEndOfReplacementCharactersWithZeroLength)
        XCTAssertEqual(s.storage.lines.count, 1)
        XCTAssertEqual(s.storage.lines[0].utf8Characters, "aaa")
        XCTAssertEqual(s.storageSelection.range.lowerBound, CodeStoragePosition(line: 0, characterIndex: "aaa".endIndex))
        XCTAssertEqual(s.storageSelection.range.upperBound, CodeStoragePosition(line: 0, characterIndex: "aaa".endIndex))
        s.insertNewLine()
        XCTAssertEqual(s.storage.lines.count, 2)
        XCTAssertEqual(s.storage.lines[0].utf8Characters, "aaa")
        XCTAssertEqual(s.storage.lines[1].utf8Characters, "")
        XCTAssertEqual(s.storageSelection.range.lowerBound, CodeStoragePosition(line: 1, characterIndex: .zero))
        XCTAssertEqual(s.storageSelection.range.upperBound, CodeStoragePosition(line: 1, characterIndex: .zero))
        s.replaceCharactersInCurrentSelection(with: "bbb", selection: .atEndOfReplacementCharactersWithZeroLength)
        XCTAssertEqual(s.storage.lines.count, 2)
        XCTAssertEqual(s.storage.lines[0].utf8Characters, "aaa")
        XCTAssertEqual(s.storage.lines[1].utf8Characters, "bbb")
        XCTAssertEqual(s.storageSelection.range.lowerBound, CodeStoragePosition(line: 1, characterIndex: "bbb".endIndex))
        XCTAssertEqual(s.storageSelection.range.upperBound, CodeStoragePosition(line: 1, characterIndex: "bbb".endIndex))
        s.selectAll()
        s.replaceCharactersInCurrentSelection(with: "", selection: .allOfReplacementCharacters)
        XCTAssertEqual(s.storage.lines.count, 1)
        XCTAssertEqual(s.storage.lines[0].utf8Characters, "")
        XCTAssertEqual(s.storageSelection.range.lowerBound, CodeStoragePosition(line: 0, characterIndex: .zero))
        XCTAssertEqual(s.storageSelection.range.upperBound, CodeStoragePosition(line: 0, characterIndex: .zero))
    }
    static var allTests = [
        ("testInsertNewLine", testInsertNewLine),
    ]
}
