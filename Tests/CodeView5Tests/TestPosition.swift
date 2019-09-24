//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/11/19.
//

import Foundation
@testable import CodeView5

typealias RangeInfo = (start: PositionInfo, end: PositionInfo)

struct PositionInfo {
    var storage: CodeTextStorage
    var lineOffset: Int
    var characterOffset: Int
    var characterUTF8Offset: Int
    var characterIndex: String.Index
    var characterCountBeforePosition: Int
    var characterCountAfterPosition: Int
    init(storage s: CodeTextStorage, lineOffset lx: Int, characterOffset cx: Int) {
        storage = s
        lineOffset = lx
        characterOffset = cx
        let line = storage.lines.atOffset(lx)
        characterIndex = line.characters.index(line.characters.startIndex, offsetBy: characterOffset)
        characterUTF8Offset = line.characters.utf8OffsetFromIndex(characterIndex)
        characterCountBeforePosition = characterOffset
        characterCountAfterPosition = line.characters[characterIndex...].count
    }
    init(storage s: CodeTextStorage, position p:CodeStoragePosition) {
        storage = s
        lineOffset = p.lineOffset
        let line = s.lines.atOffset(lineOffset)
        characterUTF8Offset = p.characterUTF8Offset
        characterIndex = line.characters.indexFromUTF8Offset(characterUTF8Offset)
        characterOffset = line.characters.distance(from: line.characters.startIndex, to: characterIndex)
        characterCountBeforePosition = characterOffset
        characterCountAfterPosition = line.characters[characterIndex...].count
    }
    var csp: CodeStoragePosition {
        return CodeStoragePosition(lineOffset: lineOffset, characterUTF8Offset: characterUTF8Offset)
    }
}

extension CodeTextStorage {
    func testPosition(line lineOffset: Int, column characterOffset: Int) -> PositionInfo {
        return PositionInfo(storage: self, lineOffset: lineOffset, characterOffset: characterOffset)
    }
}
extension CodeStorage {
    func caretPositionInfo() -> PositionInfo {
        return caretPosition.info(in: text)
    }
    func selectionRangeInfo() -> RangeInfo {
        return (selectionRange.lowerBound.info(in: text), selectionRange.upperBound.info(in: text))
    }
    func testPosition(line lineOffset: Int, column characterOffset: Int) -> PositionInfo {
        return text.testPosition(line: lineOffset, column: characterOffset)
    }
}
extension CodeEditing {
    func testPosition(line lineOffset: Int, column characterOffset: Int) -> PositionInfo {
        return storage.text.testPosition(line: lineOffset, column: characterOffset)
    }
}

extension CodeStoragePosition {
    func info(in s:CodeTextStorage) -> PositionInfo {
        return PositionInfo(storage: s, position: self)
    }
}
