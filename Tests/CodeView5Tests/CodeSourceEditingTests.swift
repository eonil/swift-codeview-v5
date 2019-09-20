import XCTest
@testable import CodeView5

final class CodeSourceEditingTests: XCTestCase {
    func testInsertNewLine() {
        let conf = CodeConfig()
        let state = CodeState()
        var ed = CodeEditing(config: conf, state: state)
        XCTAssertEqual(ed.state.source.storage.lines.count, 1)
        XCTAssertEqual(ed.state.source.storage.lines[0].content, "")
        XCTAssertEqual(ed.state.source.selectionRange.lowerBound, ed.state.testPosition(line: 0, column: 0).csp)
        XCTAssertEqual(ed.state.source.selectionRange.upperBound, ed.state.testPosition(line: 0, column: 0).csp)
        ed.process(.textTyping(.placeText("aaa")))
        XCTAssertEqual(ed.state.source.storage.lines.count, 1)
        XCTAssertEqual(ed.state.source.storage.lines[0].content, "aaa")
        XCTAssertEqual(ed.state.source.selectionRange.lowerBound, ed.state.testPosition(line: 0, column: 3).csp)
        XCTAssertEqual(ed.state.source.selectionRange.upperBound, ed.state.testPosition(line: 0, column: 3).csp)
        ed.process(.textTyping(.processEditingCommand(.insertNewline)))
        XCTAssertEqual(ed.state.source.storage.lines.count, 2)
        XCTAssertEqual(ed.state.source.storage.lines[0].content, "aaa")
        XCTAssertEqual(ed.state.source.storage.lines[1].content, "")
        XCTAssertEqual(ed.state.source.selectionRange.lowerBound, ed.state.testPosition(line: 1, column: 0).csp)
        XCTAssertEqual(ed.state.source.selectionRange.upperBound, ed.state.testPosition(line: 1, column: 0).csp)
        ed.process(.textTyping(.placeText("bbb")))
        XCTAssertEqual(ed.state.source.storage.lines.count, 2)
        XCTAssertEqual(ed.state.source.storage.lines[0].content, "aaa")
        XCTAssertEqual(ed.state.source.storage.lines[1].content, "bbb")
        XCTAssertEqual(ed.state.source.selectionRange.lowerBound, ed.state.testPosition(line: 1, column: 3).csp)
        XCTAssertEqual(ed.state.source.selectionRange.upperBound, ed.state.testPosition(line: 1, column: 3).csp)
        ed.process(.textTyping(.processEditingCommand(.selectAll)))
        ed.process(.textTyping(.placeText("")))
        XCTAssertEqual(ed.state.source.storage.lines.count, 1)
        XCTAssertEqual(ed.state.source.storage.lines[0].content, "")
        XCTAssertEqual(ed.state.source.selectionRange.lowerBound, ed.state.testPosition(line: 0, column: 0).csp)
        XCTAssertEqual(ed.state.source.selectionRange.upperBound, ed.state.testPosition(line: 0, column: 0).csp)
    }
    func testDeleteSecondLine() {
        let conf = CodeConfig()
        let state = CodeState()
        var ed = CodeEditing(config: conf, state: state)
        ed.process(.textTyping(.placeText("aaa")))
        ed.process(.textTyping(.processEditingCommand(.insertNewline)))
        ed.process(.textTyping(.placeText("bbb")))
        XCTAssertEqual(ed.state.source.storage.lines.count, 2)
        XCTAssertEqual(ed.state.source.storage.lines[0].content, "aaa")
        XCTAssertEqual(ed.state.source.storage.lines[1].content, "bbb")
        XCTAssertEqual(ed.state.source.caretPositionInfo().lineOffset, 1)
        XCTAssertEqual(ed.state.source.caretPositionInfo().characterOffset, 3)
        ed.process(.textTyping(.processEditingCommand(.deleteBackward)))
        XCTAssertEqual(ed.state.source.storage.lines.count, 2)
        XCTAssertEqual(ed.state.source.storage.lines[0].content, "aaa")
        XCTAssertEqual(ed.state.source.storage.lines[1].content, "bb")
        ed.process(.textTyping(.processEditingCommand(.deleteBackward)))
        XCTAssertEqual(ed.state.source.storage.lines.count, 2)
        XCTAssertEqual(ed.state.source.storage.lines[0].content, "aaa")
        XCTAssertEqual(ed.state.source.storage.lines[1].content, "b")
        ed.process(.textTyping(.processEditingCommand(.deleteBackward)))
        XCTAssertEqual(ed.state.source.storage.lines.count, 2)
        XCTAssertEqual(ed.state.source.storage.lines[0].content, "aaa")
        XCTAssertEqual(ed.state.source.storage.lines[1].content, "")
        ed.process(.textTyping(.processEditingCommand(.deleteBackward)))
        XCTAssertEqual(ed.state.source.storage.lines.count, 1)
        XCTAssertEqual(ed.state.source.storage.lines[0].content, "aaa")
    }
    func testInsertTwoAndDeleteOne() {
        let conf = CodeConfig()
        let state = CodeState()
        var ed = CodeEditing(config: conf, state: state)
        XCTAssertEqual(ed.state.source.storage.lines.count, 1)
        XCTAssertEqual(ed.state.source.storage.lines[0].content, "")
        XCTAssertEqual(ed.state.source.selectionRange.lowerBound, ed.state.testPosition(line: 0, column: 0).csp)
        XCTAssertEqual(ed.state.source.selectionRange.upperBound, ed.state.testPosition(line: 0, column: 0).csp)
        ed.process(.textTyping(.placeText("a")))
        XCTAssertEqual(ed.state.source.storage.lines.count, 1)
        XCTAssertEqual(ed.state.source.storage.lines[0].content, "a")
        XCTAssertEqual(ed.state.source.selectionRange.lowerBound, ed.state.testPosition(line: 0, column: 1).csp)
        XCTAssertEqual(ed.state.source.selectionRange.upperBound, ed.state.testPosition(line: 0, column: 1).csp)
        ed.process(.textTyping(.placeText("b")))
        XCTAssertEqual(ed.state.source.storage.lines.count, 1)
        XCTAssertEqual(ed.state.source.storage.lines[0].content, "ab")
        XCTAssertEqual(ed.state.source.selectionRange.lowerBound, ed.state.testPosition(line: 0, column: 2).csp)
        XCTAssertEqual(ed.state.source.selectionRange.upperBound, ed.state.testPosition(line: 0, column: 2).csp)
        ed.process(.textTyping(.processEditingCommand(.deleteBackward)))
        XCTAssertEqual(ed.state.source.storage.lines.count, 1)
        XCTAssertEqual(ed.state.source.storage.lines[0].content, "a")
        XCTAssertEqual(ed.state.source.selectionRange.lowerBound, ed.state.testPosition(line: 0, column: 1).csp)
        XCTAssertEqual(ed.state.source.selectionRange.upperBound, ed.state.testPosition(line: 0, column: 1).csp)
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
        let conf = CodeConfig()
        let state = CodeState()
        var ed = CodeEditing(config: conf, state: state)
        ed.process(.textTyping(.placeText(sample)))
        ed.process(.textTyping(.processEditingCommand(.moveToBeginningOfDocument)))
        XCTAssertEqual(ed.state.source.selectionRangeInfo().start.lineOffset, 0)
        XCTAssertEqual(ed.state.source.selectionRangeInfo().start.characterOffset, 0)
        ed.process(.textTyping(.processEditingCommand(.moveDown)))
        ed.process(.textTyping(.processEditingCommand(.moveDown)))
        ed.process(.textTyping(.processEditingCommand(.moveDown)))
        ed.process(.textTyping(.processEditingCommand(.moveDown)))
        XCTAssertEqual(ed.state.source.selectionRangeInfo().start.lineOffset, 4)
        XCTAssertEqual(ed.state.source.selectionRangeInfo().start.characterOffset, 0)
        ed.process(.textTyping(.processEditingCommand(.moveRight)))
        ed.process(.textTyping(.processEditingCommand(.moveRight)))
        ed.process(.textTyping(.processEditingCommand(.moveRight)))
        ed.process(.textTyping(.processEditingCommand(.moveRight)))
        XCTAssertEqual(ed.state.source.selectionRangeInfo().start.lineOffset, 4)
        XCTAssertEqual(ed.state.source.selectionRangeInfo().start.characterOffset, 4)
        ed.process(.textTyping(.placeText("a")))
        XCTAssertEqual(ed.state.source.selectionRangeInfo().start.lineOffset, 4)
        XCTAssertEqual(ed.state.source.selectionRangeInfo().start.characterOffset, 4+1)
        ed.process(.textTyping(.placeText("b")))
        XCTAssertEqual(ed.state.source.selectionRangeInfo().start.characterOffset, 4+2)
        ed.process(.textTyping(.processEditingCommand(.deleteBackward)))
        XCTAssertEqual(ed.state.source.selectionRangeInfo().start.characterOffset, 4+1)
        XCTAssertEqual(ed.state.source.selectionRange.upperBound, ed.state.testPosition(line: 4, column: 4+1).csp)
    }
    func testSelectAllAndDeleteBackward() {
        let conf = CodeConfig()
        let state = CodeState()
        var ed = CodeEditing(config: conf, state: state)
        ed.process(.textTyping(.placeText("aaa")))
        ed.process(.textTyping(.processEditingCommand(.insertNewline)))
        ed.process(.textTyping(.placeText("bbb")))
        ed.process(.textTyping(.processEditingCommand(.insertNewline)))
        ed.process(.textTyping(.placeText("ccc")))
        let x1 = ed.state.source.storage.lines.map({ $0.content }).joined(separator: "\n")
        XCTAssertEqual(x1, "aaa\nbbb\nccc")
        ed.process(.textTyping(.processEditingCommand(.moveToBeginningOfDocumentAndModifySelection)))
        ed.process(.textTyping(.processEditingCommand(.deleteBackward)))
        let x2 = ed.state.source.storage.lines.map({ $0.content }).joined(separator: "\n")
        XCTAssertEqual(x2, "")
    }
    
//    static var allTests = [
//        ("testInsertNewLine", testInsertNewLine),
//        ("testDeleteSecondLine", testDeleteSecondLine),
//    ]
}
