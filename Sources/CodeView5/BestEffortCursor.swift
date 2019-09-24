//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/21/19.
//

import Foundation

public extension CodeStorageEditingProtocol {
    var bestEffortCursorAtCaret: BestEffortCursor {
        return BestEffortCursor(text: text, position: caretPosition) 
    }
}
public struct BestEffortCursor {
    public let text: CodeTextStorage
    public var position: CodeStoragePosition
    public init(text x:CodeTextStorage, position p:CodeStoragePosition) {
        text = x
        position = p
    }
}
public extension BestEffortCursor {
    var lineContent: Substring {
        return text.lines.atOffset(position.lineOffset).characters
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
    /// Makes a character cursor that can move only in single line.
    var inLineCharCursor: BestEffortCharCursor {
        get {
            let n = position.characterUTF8Offset
            return lineContent.bestEffortCharCursorAtUTF8Offset(n)
        }
        set(x) {
            position.characterUTF8Offset = x.utf8Offset
        }
    }
    var isAtFirstLine: Bool { position.lineOffset == 0 }
    var isAtLastLine: Bool { position.lineOffset == text.lines.offsets.last }
    mutating func moveToEndOfPriorLine() {
        guard !isAtFirstLine else { return }
        let newLineOffset = position.lineOffset - 1
        let newLineContent = text.lines.atOffset(newLineOffset).characters
        position = CodeStoragePosition(
            lineOffset: position.lineOffset - 1,
            characterUTF8Offset: newLineContent.utf8.count)
    }
    mutating func moveToStartOfNextLine() {
        guard !isAtLastLine else { return }
        position = CodeStoragePosition(
            lineOffset: position.lineOffset + 1,
            characterUTF8Offset: 0)
    }
    mutating func moveOneCharToStart() {
        if !inLineCharCursor.isAtStart {
            inLineCharCursor.moveOneCharToStart()
        }
        else {
            moveToEndOfPriorLine()
        }
    }
    mutating func moveOneCharToEnd() {
        if !inLineCharCursor.isAtEnd {
            inLineCharCursor.moveOneCharToEnd()
        }
        else {
            moveToStartOfNextLine()
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
