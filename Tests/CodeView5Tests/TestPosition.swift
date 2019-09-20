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
    var storage: CodeStorage
    var lineOffset: Int
    var characterOffset: Int
    var characterUTF8Offset: Int
    var characterIndex: String.Index
    var characterCountBeforePosition: Int
    var characterCountAfterPosition: Int
    init(storage s: CodeStorage, lineOffset lx: Int, characterOffset cx: Int) {
        storage = s
        lineOffset = lx
        characterOffset = cx
        let line = storage.lines.atOffset(lx)
        characterIndex = line.content.index(line.content.startIndex, offsetBy: characterOffset)
        characterUTF8Offset = line.content.utf8OffsetFromIndex(characterIndex)
        characterCountBeforePosition = characterOffset
        characterCountAfterPosition = line.content[characterIndex...].count
    }
    init(storage s: CodeStorage, position p:CodeStoragePosition) {
        storage = s
        lineOffset = p.lineOffset
        let line = s.lines.atOffset(lineOffset)
        characterUTF8Offset = p.characterUTF8Offset
        characterIndex = line.content.indexFromUTF8Offset(characterUTF8Offset)
        characterOffset = line.content.distance(from: line.content.startIndex, to: characterIndex)
        characterCountBeforePosition = characterOffset
        characterCountAfterPosition = line.content[characterIndex...].count
    }
    var csp: CodeStoragePosition {
        return CodeStoragePosition(lineOffset: lineOffset, characterUTF8Offset: characterUTF8Offset)
    }
}

extension CodeStorage {
    func testPosition(line lineOffset: Int, column characterOffset: Int) -> PositionInfo {
        return PositionInfo(storage: self, lineOffset: lineOffset, characterOffset: characterOffset)
    }
}
extension CodeSource {
    func caretPositionInfo() -> PositionInfo {
        return caretPosition.info(in: storage)
    }
    func selectionRangeInfo() -> RangeInfo {
        return (selectionRange.lowerBound.info(in: storage), selectionRange.upperBound.info(in: storage))
    }
    func testPosition(line lineOffset: Int, column characterOffset: Int) -> PositionInfo {
        return storage.testPosition(line: lineOffset, column: characterOffset)
    }
}
extension CodeState {
    func testPosition(line lineOffset: Int, column characterOffset: Int) -> PositionInfo {
        return source.storage.testPosition(line: lineOffset, column: characterOffset)
    }
}

extension CodeStoragePosition {
    func info(in s:CodeStorage) -> PositionInfo {
        return PositionInfo(storage: s, position: self)
    }
}
