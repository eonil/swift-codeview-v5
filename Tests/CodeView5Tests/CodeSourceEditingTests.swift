import XCTest
@testable import CodeView5

final class CodeSourceEditingTests: XCTestCase {
    func testInsertNewLine() {
        var ed = CodeEditing()
        XCTAssertEqual(ed.storage.text.lines.count, 1)
        XCTAssertEqual(ed.storage.text.lines[0].characters, "")
        XCTAssertEqual(ed.storage.selectionRange.lowerBound, ed.testPosition(line: 0, column: 0).csp)
        XCTAssertEqual(ed.storage.selectionRange.upperBound, ed.testPosition(line: 0, column: 0).csp)
        ed.apply(.typing(.placeText("aaa")))
        XCTAssertEqual(ed.storage.text.lines.count, 1)
        XCTAssertEqual(ed.storage.text.lines[0].characters, "aaa")
        XCTAssertEqual(ed.storage.selectionRange.lowerBound, ed.testPosition(line: 0, column: 3).csp)
        XCTAssertEqual(ed.storage.selectionRange.upperBound, ed.testPosition(line: 0, column: 3).csp)
        ed.apply(.typing(.processEditingCommand(.insertNewline)))
        XCTAssertEqual(ed.storage.text.lines.count, 2)
        XCTAssertEqual(ed.storage.text.lines[0].characters, "aaa")
        XCTAssertEqual(ed.storage.text.lines[1].characters, "")
        XCTAssertEqual(ed.storage.selectionRange.lowerBound, ed.testPosition(line: 1, column: 0).csp)
        XCTAssertEqual(ed.storage.selectionRange.upperBound, ed.testPosition(line: 1, column: 0).csp)
        ed.apply(.typing(.placeText("bbb")))
        XCTAssertEqual(ed.storage.text.lines.count, 2)
        XCTAssertEqual(ed.storage.text.lines[0].characters, "aaa")
        XCTAssertEqual(ed.storage.text.lines[1].characters, "bbb")
        XCTAssertEqual(ed.storage.selectionRange.lowerBound, ed.testPosition(line: 1, column: 3).csp)
        XCTAssertEqual(ed.storage.selectionRange.upperBound, ed.testPosition(line: 1, column: 3).csp)
        ed.apply(.typing(.processEditingCommand(.selectAll)))
        ed.apply(.typing(.placeText("")))
        XCTAssertEqual(ed.storage.text.lines.count, 1)
        XCTAssertEqual(ed.storage.text.lines[0].characters, "")
        XCTAssertEqual(ed.storage.selectionRange.lowerBound, ed.testPosition(line: 0, column: 0).csp)
        XCTAssertEqual(ed.storage.selectionRange.upperBound, ed.testPosition(line: 0, column: 0).csp)
    }
    func testDeleteSecondLine() {
        var ed = CodeEditing()
        ed.apply(.typing(.placeText("aaa")))
        ed.apply(.typing(.processEditingCommand(.insertNewline)))
        ed.apply(.typing(.placeText("bbb")))
        XCTAssertEqual(ed.storage.text.lines.count, 2)
        XCTAssertEqual(ed.storage.text.lines[0].characters, "aaa")
        XCTAssertEqual(ed.storage.text.lines[1].characters, "bbb")
        XCTAssertEqual(ed.storage.caretPositionInfo().lineOffset, 1)
        XCTAssertEqual(ed.storage.caretPositionInfo().characterOffset, 3)
        ed.apply(.typing(.processEditingCommand(.deleteBackward)))
        XCTAssertEqual(ed.storage.text.lines.count, 2)
        XCTAssertEqual(ed.storage.text.lines[0].characters, "aaa")
        XCTAssertEqual(ed.storage.text.lines[1].characters, "bb")
        ed.apply(.typing(.processEditingCommand(.deleteBackward)))
        XCTAssertEqual(ed.storage.text.lines.count, 2)
        XCTAssertEqual(ed.storage.text.lines[0].characters, "aaa")
        XCTAssertEqual(ed.storage.text.lines[1].characters, "b")
        ed.apply(.typing(.processEditingCommand(.deleteBackward)))
        XCTAssertEqual(ed.storage.text.lines.count, 2)
        XCTAssertEqual(ed.storage.text.lines[0].characters, "aaa")
        XCTAssertEqual(ed.storage.text.lines[1].characters, "")
        ed.apply(.typing(.processEditingCommand(.deleteBackward)))
        XCTAssertEqual(ed.storage.text.lines.count, 1)
        XCTAssertEqual(ed.storage.text.lines[0].characters, "aaa")
    }
    func testInsertTwoAndDeleteOne() {
        var ed = CodeEditing()
        XCTAssertEqual(ed.storage.text.lines.count, 1)
        XCTAssertEqual(ed.storage.text.lines[0].characters, "")
        XCTAssertEqual(ed.storage.selectionRange.lowerBound, ed.testPosition(line: 0, column: 0).csp)
        XCTAssertEqual(ed.storage.selectionRange.upperBound, ed.testPosition(line: 0, column: 0).csp)
        ed.apply(.typing(.placeText("a")))
        XCTAssertEqual(ed.storage.text.lines.count, 1)
        XCTAssertEqual(ed.storage.text.lines[0].characters, "a")
        XCTAssertEqual(ed.storage.selectionRange.lowerBound, ed.testPosition(line: 0, column: 1).csp)
        XCTAssertEqual(ed.storage.selectionRange.upperBound, ed.testPosition(line: 0, column: 1).csp)
        ed.apply(.typing(.placeText("b")))
        XCTAssertEqual(ed.storage.text.lines.count, 1)
        XCTAssertEqual(ed.storage.text.lines[0].characters, "ab")
        XCTAssertEqual(ed.storage.selectionRange.lowerBound, ed.testPosition(line: 0, column: 2).csp)
        XCTAssertEqual(ed.storage.selectionRange.upperBound, ed.testPosition(line: 0, column: 2).csp)
        ed.apply(.typing(.processEditingCommand(.deleteBackward)))
        XCTAssertEqual(ed.storage.text.lines.count, 1)
        XCTAssertEqual(ed.storage.text.lines[0].characters, "a")
        XCTAssertEqual(ed.storage.selectionRange.lowerBound, ed.testPosition(line: 0, column: 1).csp)
        XCTAssertEqual(ed.storage.selectionRange.upperBound, ed.testPosition(line: 0, column: 1).csp)
    }
    func testCornerCase1() {
        let sample =
"""


    fn main() {
        abcdef();
        
    }

    fn abcdef() {

    }
"""
        
        var ed = CodeEditing()
        ed.apply(.typing(.placeText(sample)))
        ed.apply(.typing(.processEditingCommand(.moveToBeginningOfDocument)))
        XCTAssertEqual(ed.storage.selectionRangeInfo().start.lineOffset, 0)
        XCTAssertEqual(ed.storage.selectionRangeInfo().start.characterOffset, 0)
        ed.apply(.typing(.processEditingCommand(.moveDown)))
        ed.apply(.typing(.processEditingCommand(.moveDown)))
        ed.apply(.typing(.processEditingCommand(.moveDown)))
        ed.apply(.typing(.processEditingCommand(.moveDown)))
        XCTAssertEqual(ed.storage.selectionRangeInfo().start.lineOffset, 4)
        XCTAssertEqual(ed.storage.selectionRangeInfo().start.characterOffset, 0)
        ed.apply(.typing(.processEditingCommand(.moveRight)))
        ed.apply(.typing(.processEditingCommand(.moveRight)))
        ed.apply(.typing(.processEditingCommand(.moveRight)))
        ed.apply(.typing(.processEditingCommand(.moveRight)))
        XCTAssertEqual(ed.storage.selectionRangeInfo().start.lineOffset, 4)
        XCTAssertEqual(ed.storage.selectionRangeInfo().start.characterOffset, 4)
        ed.apply(.typing(.placeText("a")))
        XCTAssertEqual(ed.storage.selectionRangeInfo().start.lineOffset, 4)
        XCTAssertEqual(ed.storage.selectionRangeInfo().start.characterOffset, 4+1)
        ed.apply(.typing(.placeText("b")))
        XCTAssertEqual(ed.storage.selectionRangeInfo().start.characterOffset, 4+2)
        ed.apply(.typing(.processEditingCommand(.deleteBackward)))
        XCTAssertEqual(ed.storage.selectionRangeInfo().start.characterOffset, 4+1)
        XCTAssertEqual(ed.storage.selectionRange.upperBound, ed.testPosition(line: 4, column: 4+1).csp)
    }
    func testSelectAllAndDeleteBackward() {
        var ed = CodeEditing()
        ed.apply(.typing(.placeText("aaa")))
        ed.apply(.typing(.processEditingCommand(.insertNewline)))
        ed.apply(.typing(.placeText("bbb")))
        ed.apply(.typing(.processEditingCommand(.insertNewline)))
        ed.apply(.typing(.placeText("ccc")))
        let x1 = ed.storage.text.lines.map({ $0.characters }).joined(separator: "\n")
        XCTAssertEqual(x1, "aaa\nbbb\nccc")
        ed.apply(.typing(.processEditingCommand(.moveToBeginningOfDocumentAndModifySelection)))
        ed.apply(.typing(.processEditingCommand(.deleteBackward)))
        let x2 = ed.storage.text.lines.map({ $0.characters }).joined(separator: "\n")
        XCTAssertEqual(x2, "")
    }
    
//    static var allTests = [
//        ("testInsertNewLine", testInsertNewLine),
//        ("testDeleteSecondLine", testDeleteSecondLine),
//    ]
}
