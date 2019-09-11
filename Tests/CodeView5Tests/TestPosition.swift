//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/11/19.
//

import Foundation
@testable import CodeView5

struct TestPosition {
    var storage: CodeStorage
    var lineOffset: Int
    var characterOffset: Int
    var characterIndex: String.Index
    var characterCountBeforePosition: Int
    var characterCountAfterPosition: Int
    init(storage s: CodeStorage, lineOffset lx: Int, characterOffset cx: Int) {
        storage = s
        lineOffset = lx
        characterOffset = cx
        let line = storage.lines[storage.lines.startIndex.advanced(by: lineOffset)]
        characterIndex = line.content.index(line.content.startIndex, offsetBy: characterOffset)
        characterCountBeforePosition = characterOffset
        characterCountAfterPosition = line.content[characterIndex...].count
    }
    var csp: CodeStoragePosition {
        return CodeStoragePosition(lineIndex: lineOffset, characterIndex: characterIndex)
    }
}
extension CodeStorage {
    func testPosition(line lineOffset: Int, column characterOffset: Int) -> TestPosition {
        return TestPosition(storage: self, lineOffset: lineOffset, characterOffset: characterOffset)
    }
}
extension CodeSource {
    func testPosition(line lineOffset: Int, column characterOffset: Int) -> TestPosition {
        return storage.testPosition(line: lineOffset, column: characterOffset)
    }
}
extension CodeStoragePosition {
    func testPosition(in s:CodeStorage) -> TestPosition {
        let lineOffset = s.lines.distance(from: s.lines.startIndex, to: lineIndex)
        let line = s.lines[lineIndex]
        let charOffset = line.content.distance(from: line.content.startIndex, to: characterIndex)
        return TestPosition(storage: s, lineOffset: lineOffset, characterOffset: charOffset)
    }
}
