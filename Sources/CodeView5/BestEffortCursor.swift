//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/21/19.
//

import Foundation

extension CodeStorageEditingProtocol {
    var bestEffortCursorAtCaret: BestEffortCursor {
        return BestEffortCursor(storage: text, position: caretPosition) 
    }
}
struct BestEffortCursor {
    let storage: CodeTextStorage
    var position: CodeStoragePosition
    var lineContent: Substring {
        return storage.lines.atOffset(position.lineOffset).content
    }
//    var isOnEmptyLine: Bool {
//        return lineContent.isEmpty
//    }
//    var isAtStartOfLine: Bool {
//        return position.characterUTF8Offset == 0
//    }
//    var isAtEndOfLine: Bool {
//        return position.characterUTF8Offset == lineContent.utf8.count
//    }
//    var charIndex: Substring.Index {
//        let charIndex = lineContent.index(lineContent.startIndex, offsetBy: position.characterUTF8Offset)
//        return charIndex
//    }
//    var charIndexBefore: Substring.Index? {
//        guard !isAtStartOfLine else { return nil }
//        return lineContent.index(before: charIndex)
//    }
//    var charIndexAfter: Substring.Index? {
//        guard !isAtEndOfLine else { return nil }
//        return lineContent.index(before: charIndex)
//    }
//    var char: Character? {
//        guard !isAtEndOfLine else { return nil }
//        return lineContent[charIndex]
//    }
//    var charBefore: Character? {
//        guard let i = charIndexBefore else { return nil }
//        return lineContent[i]
//    }
//    var charAfter: Character? {
//        guard let i = charIndexAfter else { return nil }
//        return lineContent[i]
//    }
    var charCursor: BestEffortCharCursor {
        get {
            let n = position.characterUTF8Offset
            return lineContent.bestEffortCharCursorAtUTF8Offset(n)
        }
        set(x) {
            position.characterUTF8Offset = x.utf8Offset
        }
    }
//    mutating func moveOneCharToStart() {
//        self.charCursor.moveOneCharToEnd()
//        let n = position.characterUTF8Offset
//        var cc = lineContent.bestEffortCharCursorAtUTF8Offset(n)
//        cc.moveOneCharToStart()
//        position.characterUTF8Offset = cc.utf8Offset
//    }
//    mutating func moveOneCharToEnd() {
//        let n = position.characterUTF8Offset
//        var cc = lineContent.bestEffortCharCursorAtUTF8Offset(n)
//        cc.moveOneCharToEnd()
//        position.characterUTF8Offset = cc.utf8Offset
//    }
//    mutating func moveOneWordToStart() {
//        let n = position.characterUTF8Offset
//        var cc = lineContent.bestEffortCharCursorAtUTF8Offset(n)
//        cc.moveOneWordToStart()
//        position.characterUTF8Offset = cc.utf8Offset
//    }
//    mutating func moveOneWordToEnd() {
//        let n = position.characterUTF8Offset
//        var cc = lineContent.bestEffortCharCursorAtUTF8Offset(n)
//        cc.moveOneWordToEnd()
//        position.characterUTF8Offset = cc.utf8Offset
//    }
//    mutating func moveOneSubwordToStart() {
//        let n = position.characterUTF8Offset
//        var cc = lineContent.bestEffortCharCursorAtUTF8Offset(n)
//        cc.moveOneSubwordToStart()
//        position.characterUTF8Offset = cc.utf8Offset
//    }
//    mutating func moveOneSubwordToEnd() {
//        let n = position.characterUTF8Offset
//        var cc = lineContent.bestEffortCharCursorAtUTF8Offset(n)
//        cc.moveOneSubwordToEnd()
//        position.characterUTF8Offset = cc.utf8Offset
//    }
}
