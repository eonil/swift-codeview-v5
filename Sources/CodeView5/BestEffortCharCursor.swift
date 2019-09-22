//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/21/19.
//

import Foundation

//extension CodeSourceEditing {
//    func bestEffortCharCursorAtCaret() -> BestEffortCharCursor {
//        let p = caretPosition
//        let lineContent = storage.lines.atOffset(p.lineOffset).content
//        return lineContent.bestEffortCharCursorAtUTF8Offset(p.characterUTF8Offset)
//    }
//}
public extension Substring {
    func bestEffortCharCursorAtUTF8Offset(_ utf8Offset:Int) -> BestEffortCharCursor {
        var cc = BestEffortCharCursor(content: self)
        cc.position = utf8.index(startIndex, offsetBy: utf8Offset)
        return cc
    }
}

/// Tries best to fulfill order but does not guarantee desired result.
public struct BestEffortCharCursor {
    public let content: Substring
    public var position: Substring.Index
    public init(content x:Substring) {
        content = x
        position = x.startIndex
    }
}
public extension BestEffortCharCursor {
    var utf8Offset: Int { content.utf8.distance(from: content.startIndex, to: position) }
    var isEmpty: Bool { content.isEmpty }
    var isAtStart: Bool { content.startIndex == position }
    var isAtEnd: Bool { position == content.endIndex }
    var hasChar: Bool { content.indices.contains(position) }
    var char: Character? {
        guard !isEmpty && !isAtEnd else { return nil }
        return content[position]
    }
    var priorChar: Character? {
        guard !isAtStart else { return nil }
        var preview = self
        preview.moveOneCharToStart()
        return preview.char
    }
    var nextChar: Character? {
        guard !isAtEnd else { return nil }
        var preview = self
        preview.moveOneCharToEnd()
        return preview.char
    }
    mutating func moveOneCharToStart() {
        guard !isAtStart else { return }
        position = content.index(before: position)
    }
    mutating func moveOneCharToEnd() {
        guard !isAtEnd else { return }
        position = content.index(after: position)
    }
}
public extension BestEffortCharCursor {
    ///
    /// A position moved by one word from current caret.
    /// A "word" is consecutive "letter" characters.
    ///
    /// Two caes.
    ///
    ///     abc.de_
    ///     abcd.._
    ///
    mutating func moveOneWordToStart() {
        skipAllNonLettersToStart()
        while priorChar?.isLetter == true { moveOneCharToStart()}
    }
    mutating func moveOneWordToEnd() {
        skipAllNonLettersToEnd()
        while nextChar?.isLetter == true { moveOneCharToEnd()}
    }
    mutating func moveOneSubwordToStart() {
        if priorChar?.isLetter == false {
            skipAllNonLettersToStart()
        }
        else {
            if priorChar?.isUppercase == true {
                while priorChar?.isUppercase == true { moveOneCharToStart()}
            }
            else {
                while priorChar?.isLowercase == true { moveOneCharToStart()}
                if priorChar?.isUppercase == true { moveOneCharToStart()}
            }
        }
    }
    mutating func moveOneSubwordToEnd() {
        if char?.isLetter == false {
            skipAllNonLettersToEnd()
        }
        else {
            if char?.isLowercase == true {
                while char?.isLowercase == true { moveOneCharToEnd()}
                return
            }
            if char?.isUppercase == true && nextChar?.isLowercase == true {
                moveOneCharToEnd()
                while char?.isLowercase == true { moveOneCharToEnd()}
            }
            else {
                ///
                /// Corner cases.
                ///
                ///     XMLZoo
                ///     XML.Zoo
                ///     xmlzooo
                ///
                while char?.isUppercase == true && nextChar?.isLowercase == false { moveOneCharToEnd() }
            }
        }
    }
    mutating func skipAllNonLettersToStart() {
        while priorChar?.isLetter == false { moveOneCharToStart() }
    }
    mutating func skipAllNonLettersToEnd() {
        while char?.isLetter == false { moveOneCharToEnd() }
    }
    
    mutating func moveToStart() {
        position = content.startIndex
    }
    mutating func moveToEnd() {
        position = content.endIndex
    }
}
