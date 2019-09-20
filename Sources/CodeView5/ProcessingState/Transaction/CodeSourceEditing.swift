//
//  CodeSourceEditing.swift
//  
//
//  Created by Henry Hathaway on 9/11/19.
//

import Foundation
import AppKit

/// Represents an editable code source.
///
/// Performs line/character based editing operations.
///
protocol CodeSourceEditing {
    var storage: CodeStorage { get }
    var caretPosition: CodeStoragePosition { get set }
    var selectionAnchorPosition: CodeStoragePosition? { get set }
    var selectionRange: Range<CodeStoragePosition> { get set }
    mutating func replaceCharactersInCurrentSelection(with s:String)
}

// MARK: - Query
extension CodeSourceEditing {
    var startPosition: CodeStoragePosition {
        return CodeStoragePosition(lineOffset: 0, characterUTF8Offset: 0)
    }
    var endPosition: CodeStoragePosition {
        /// `CodeSource` guarantees having one line at least always.
        return CodeStoragePosition(lineOffset: storage.lines.count-1, characterUTF8Offset: storage.lines.last!.content.utf8.count)
    }
    func leftCharacterCaretPosition() -> CodeStoragePosition {
        guard caretPosition != startPosition else { return startPosition }
        let p = caretPosition
        let lineContent = storage.lines[storage.lines.startIndex + p.lineOffset].content
        if 0 < p.characterUTF8Offset {
            let charIndex = lineContent.utf8.index(lineContent.utf8.startIndex, offsetBy: p.characterUTF8Offset)
            let newCharIndex = lineContent.index(before: charIndex)
            let utf8Offset = lineContent.utf8.distance(from: lineContent.utf8.startIndex, to: newCharIndex)
            return CodeStoragePosition(lineOffset: p.lineOffset, characterUTF8Offset: utf8Offset)
        }
        else {
            return endPositionOfUpLine()
        }
    }
    func rightCharacterCaretPosition() -> CodeStoragePosition {
        guard caretPosition != endPosition else { return endPosition }
        let p = caretPosition
        let lineContent = storage.lines[storage.lines.startIndex + p.lineOffset].content
        if p.characterUTF8Offset < lineContent.utf8.count {
            let charIndex = lineContent.utf8.index(lineContent.utf8.startIndex, offsetBy: p.characterUTF8Offset)
            let newCharIndex = lineContent.index(after: charIndex)
            let utf8Offset = lineContent.utf8.distance(from: lineContent.utf8.startIndex, to: newCharIndex)
            return CodeStoragePosition(lineOffset: p.lineOffset, characterUTF8Offset: utf8Offset)
        }
        else {
            return startPositionOfDownLine()
        }
    }
    func leftEndPositionOfLine1(at lineOffset:Int) -> CodeStoragePosition {
        let q = CodeStoragePosition(lineOffset: lineOffset, characterUTF8Offset: 0)
        return q
    }
    func rightEndPositionOfLine1(at lineOffset:Int) -> CodeStoragePosition {
        let line = storage.lines[storage.lines.startIndex + lineOffset]
        let q = CodeStoragePosition(lineOffset: lineOffset, characterUTF8Offset: line.content.utf8.count)
        return q
    }
    func endPositionOfUpLine() -> CodeStoragePosition {
        guard caretPosition != startPosition else { return startPosition }
        let lineOffset = caretPosition.lineOffset - 1
        let lineContent = storage.lines[storage.lines.startIndex + lineOffset].content
        return CodeStoragePosition(lineOffset: lineOffset, characterUTF8Offset: lineContent.utf8.count)
    }
    func startPositionOfDownLine() -> CodeStoragePosition {
        guard caretPosition != endPosition else { return endPosition }
        let lineOffset = caretPosition.lineOffset + 1
        return CodeStoragePosition(lineOffset: lineOffset, characterUTF8Offset: 0)
    }
    func characterIndex(at x:CGFloat, in line:CodeLine, with f:NSFont) -> String.Index? {
        let ctline = CTLine.make(with: line.content, font: f)
        let utf16Offset = CTLineGetStringIndexForPosition(ctline, CGPoint(x: x, y: 0))
        guard utf16Offset != kCFNotFound else { return nil }
        return line.content.utf16.index(line.content.utf16.startIndex, offsetBy: utf16Offset)
    }
    func characterUTF8Offset(at x:CGFloat, in line:CodeLine, with f:NSFont) -> Int? {
        let ctline = CTLine.make(with: line.content, font: f)
        let utf16Offset = CTLineGetStringIndexForPosition(ctline, CGPoint(x: x, y: 0))
        guard utf16Offset != kCFNotFound else { return nil }
        let charIndex = line.content.utf16.index(line.content.utf16.startIndex, offsetBy: utf16Offset)
        let charUTF8Offset = line.content.utf8.distance(from: line.content.utf8.startIndex, to: charIndex)
        return charUTF8Offset
    }
//    func characterOffset(at x:CGFloat, in line:CodeLine, with g:NSFont) -> Int? {
//        let ctline = CTLine.make(with: line.content, font: f)
//        let utf16Offset = CTLineGetStringIndexForPosition(ctline, CGPoint(x: x, y: 0))
//        guard utf16Offset != kCFNotFound else { return nil }
//        return line.content.utf16.index(line.content.utf16.startIndex, offsetBy: utf16Offset)
//    }
}

// MARK: - Edit Command
extension CodeSourceEditing {
    mutating func modifySelectionWithAnchor(to p:CodeStoragePosition) {
        let oldAnchorPosition = selectionAnchorPosition ?? caretPosition
        let a = min(p, oldAnchorPosition)
        let b = max(p, oldAnchorPosition)
        caretPosition = p
        selectionRange = a..<b
        selectionAnchorPosition = oldAnchorPosition
    }
    mutating func moveCaret(to p:CodeStoragePosition) {
        caretPosition = p
        selectionRange = p..<p
        selectionAnchorPosition = nil
    }
    mutating func moveCaretAndModifySelection(to p:CodeStoragePosition) {
        modifySelectionWithAnchor(to: p)
    }
    mutating func selectAll() {
        selectionRange = startPosition..<endPosition
    }
    
    /// Inserts a new line replacing current selection.
    mutating func insertNewLine(config: CodeConfig) {
        replaceCharactersInCurrentSelection(with: "\n")
        // Now new selection's lineOffset > 0.
        if config.editing.autoIndent {
            let upLineOffset = caretPosition.lineOffset-1
            let upLineIndex = storage.lines.startIndex + upLineOffset
            let upLine = storage.lines[upLineIndex]
            let tabReplacement = config.editing.makeTabReplacement()
            let n = upLine.countPrefix(tabReplacement)
            for _ in 0..<n {
                replaceCharactersInCurrentSelection(with: tabReplacement)
            }
        }
    }
//    mutating func insertBacktab(config: CodeConfig) {
//        let line = storage.lines[caretPosition.lineIndex]
//        let n = line.countPrefix(" ")
//        guard n > 0 else { return }
//        let m = (n - 1) / config.editing.tabSpaceCount
//        let k = n - m * config.editing.tabSpaceCount
//        for _ in 0..<k {
//            moveCaretAndModifySelection(to: leftCharacterCaretPosition())
//            replaceCharactersInCurrentSelection(with: "")
//        }
////        replaceCharactersInCurrentSelection(with: config.tabReplacement)
//    }
}
