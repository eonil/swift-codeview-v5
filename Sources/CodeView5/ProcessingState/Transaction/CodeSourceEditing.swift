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
        CodeStoragePosition(lineIndex: 0, characterIndex: storage.lines.first!.startIndex)
    }
    var endPosition: CodeStoragePosition {
        /// `CodeSource` guarantees having one line at least always.
        CodeStoragePosition(lineIndex: storage.lines.count-1, characterIndex: storage.lines.last!.endIndex)
    }
    func leftCharacterCaretPosition() -> CodeStoragePosition {
        guard caretPosition != startPosition else { return startPosition }
        let p = caretPosition
        let line = storage.lines[p.lineIndex]
        if line.startIndex < p.characterIndex {
            let i = line.index(before: p.characterIndex)
            return CodeStoragePosition(lineIndex: p.lineIndex, characterIndex: i)
        }
        else {
            return endPositionOfUpLine()
        }
    }
    func rightCharacterCaretPosition() -> CodeStoragePosition {
        guard caretPosition != endPosition else { return endPosition }
        let p = caretPosition
        let line = storage.lines[p.lineIndex]
        if p.characterIndex < line.endIndex {
            let i = line.index(after: p.characterIndex)
            return CodeStoragePosition(lineIndex: p.lineIndex, characterIndex: i)
        }
        else {
            return startPositionOfDownLine()
        }
    }
    func leftEndPositionOfLine(at lineIndex:Int) -> CodeStoragePosition {
        let line = storage.lines[lineIndex]
        let q = CodeStoragePosition(lineIndex: lineIndex, characterIndex: line.startIndex)
        return q
    }
    func rightEndPositionOfLine(at lineIndex:Int) -> CodeStoragePosition {
        let line = storage.lines[lineIndex]
        let q = CodeStoragePosition(lineIndex: lineIndex, characterIndex: line.endIndex)
        return q
    }
    func endPositionOfUpLine() -> CodeStoragePosition {
        guard caretPosition != startPosition else { return startPosition }
        let lineIndex = caretPosition.lineIndex - 1
        let charIndex = storage.lines[lineIndex].endIndex
        return CodeStoragePosition(lineIndex: lineIndex, characterIndex: charIndex)
    }
    func startPositionOfDownLine() -> CodeStoragePosition {
        guard caretPosition != endPosition else { return endPosition }
        let lineIndex = caretPosition.lineIndex + 1
        let charIndex = storage.lines[lineIndex].startIndex
        return CodeStoragePosition(lineIndex: lineIndex, characterIndex: charIndex)
    }
    func characterIndex(at x:CGFloat, in line:CodeLine, with f:NSFont) -> String.Index? {
        let ctline = CTLine.make(with: line.content, font: f)
        let utf16Offset = CTLineGetStringIndexForPosition(ctline, CGPoint(x: x, y: 0))
        guard utf16Offset != kCFNotFound else { return nil }
        return line.content.utf16.index(line.content.utf16.startIndex, offsetBy: utf16Offset)
    }
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
        if config.editing.autoIndent {
            let upLine = storage.lines[caretPosition.lineIndex-1]
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
