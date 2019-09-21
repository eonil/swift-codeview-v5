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
extension Substring {
    func bestEffortCharCursorAtUTF8Offset(_ utf8Offset:Int) -> BestEffortCharCursor {
        var cc = BestEffortCharCursor(content: self)
        cc.position = utf8.index(startIndex, offsetBy: utf8Offset)
        return cc
    }
}

/// Tries best to fulfill order but does not guarantee desired result.
struct BestEffortCharCursor {
    let content: Substring
    var position: Substring.Index
    init(content x:Substring) {
        content = x
        position = x.startIndex
    }
    var utf8Offset: Int { content.utf8.distance(from: content.startIndex, to: position) }
    var isEmpty: Bool { content.isEmpty }
    var isAtStart: Bool { content.startIndex == position }
    var isAtEnd: Bool { position == content.endIndex }
    var hasChar: Bool { content.indices.contains(position) }
    var char: Character? {
        guard !isEmpty && !isAtEnd else { return nil }
        return content[position]
    }
    var charBefore: Character? {
        guard !isAtStart else { return nil }
        var preview = self
        preview.moveOneCharToStart()
        return preview.char
    }
    var charAfter: Character? {
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
extension BestEffortCharCursor {
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
        while charBefore?.isLetter == true { moveOneCharToStart()}
    }
    mutating func moveOneWordToEnd() {
        skipAllNonLettersToEnd()
        while charAfter?.isLetter == true { moveOneCharToEnd()}
    }
    mutating func moveOneSubwordToStart() {
        if charBefore?.isLetter == false {
            skipAllNonLettersToStart()
        }
        else {
            if charBefore?.isUppercase == true {
                while charBefore?.isUppercase == true { moveOneCharToStart()}
            }
            else {
                while charBefore?.isLowercase == true { moveOneCharToStart()}
                if charBefore?.isUppercase == true { moveOneCharToStart()}
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
            if char?.isUppercase == true && charAfter?.isLowercase == true {
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
                while char?.isUppercase == true && charAfter?.isLowercase == false { moveOneCharToEnd() }
            }
        }
    }
    mutating func skipAllNonLettersToStart() {
        while charBefore?.isLetter == false { moveOneCharToStart() }
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

/// Returns `false` if any of input is `nil`.
///
///     Foo.BarZoo
///
private func areNonNilSameCases(_ a:Character?, _ b:Character?) -> Bool {
    guard let a1 = a else { return false }
    guard let b1 = b else { return false }
    return a1.isLowercase == b1.isLowercase
}
