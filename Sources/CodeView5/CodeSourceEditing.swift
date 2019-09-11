//
//  CodeSourceEditing.swift
//  
//
//  Created by Henry Hathaway on 9/11/19.
//

import Foundation
import AppKit

/// Represents an editable code source.
protocol CodeSourceEditing {
    var config: CodeSourceConfig { get }
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
    private mutating func moveToEndOfUpLine() {
        guard caretPosition != startPosition else { return }
        let lineIndex = caretPosition.lineIndex - 1
        let charIndex = storage.lines[lineIndex].endIndex
        caretPosition = CodeStoragePosition(lineIndex: lineIndex, characterIndex: charIndex)
        selectionRange = caretPosition..<caretPosition
        selectionAnchorPosition = nil
    }
    private mutating func moveToStartOfDownLine() {
        guard caretPosition != endPosition else { return }
        let lineIndex = caretPosition.lineIndex + 1
        let charIndex = storage.lines[lineIndex].startIndex
        caretPosition = CodeStoragePosition(lineIndex: lineIndex, characterIndex: charIndex)
        selectionRange = caretPosition..<caretPosition
        selectionAnchorPosition = nil
    }
    
    mutating func moveLeft() {
        guard caretPosition != startPosition else { return }
        let p = caretPosition
        let line = storage.lines[p.lineIndex]
        if line.startIndex < p.characterIndex {
            let i = line.index(before: p.characterIndex)
            let q = CodeStoragePosition(lineIndex: p.lineIndex, characterIndex: i)
            caretPosition = q
            selectionRange = caretPosition..<caretPosition
            selectionAnchorPosition = nil
        }
        else {
            moveToEndOfUpLine()
        }
    }
    mutating func moveRight() {
        guard caretPosition != endPosition else { return }
        let p = caretPosition
        let line = storage.lines[p.lineIndex]
        if p.characterIndex < line.endIndex {
            let i = line.index(after: p.characterIndex)
            let q = CodeStoragePosition(lineIndex: p.lineIndex, characterIndex: i)
            caretPosition = q
            selectionRange = caretPosition..<caretPosition
            selectionAnchorPosition = nil
        }
        else {
            moveToStartOfDownLine()
        }
    }
    /// Moves caret to left by one character and expand selection to new caret position.
    mutating func moveLeftAndModifySelection() {
        var x = self
        x.moveLeft()
        modifySelectionWithAnchor(to: x.caretPosition)
    }
    /// Moves caret to right by one character and expand selection to new caret position.
    mutating func moveRightAndModifySelection() {
        var x = self
        x.moveRight()
        modifySelectionWithAnchor(to: x.caretPosition)
    }
    mutating func moveToLeftEndOfLine() {
        let p = caretPosition
        let line = storage.lines[p.lineIndex]
        let q = CodeStoragePosition(lineIndex: p.lineIndex, characterIndex: line.startIndex)
        caretPosition = q
        selectionRange = q..<q
        selectionAnchorPosition = nil
    }
    mutating func moveToRightEndOfLine() {
        let p = caretPosition
        let line = storage.lines[p.lineIndex]
        let q = CodeStoragePosition(lineIndex: p.lineIndex, characterIndex: line.endIndex)
        caretPosition = q
        selectionRange = q..<q
        selectionAnchorPosition = nil
    }
    mutating func moveToLeftEndOfLineAndModifySelection() {
        var x = self
        x.moveToLeftEndOfLine()
        modifySelectionWithAnchor(to: x.caretPosition)
    }
    mutating func moveToRightEndOfLineAndModifySelection() {
        var x = self
        x.moveToRightEndOfLine()
        modifySelectionWithAnchor(to: x.caretPosition)
    }
    mutating func moveUp(font f: NSFont, at x: CGFloat) {
        let p = caretPosition
        guard 0 < p.lineIndex else { return }
        let li = p.lineIndex - 1
        let line = storage.lines[li]
        let ci = characterIndex(at: x, in: line, with: f) ?? line.endIndex
        let q = CodeStoragePosition(lineIndex: li, characterIndex: ci)
        caretPosition = q
        selectionRange = q..<q
        selectionAnchorPosition = nil
    }
    mutating func moveDown(font f:NSFont, at x:CGFloat) {
        let p = caretPosition
        guard p.lineIndex < storage.lines.count-1 else { return }
        let li = p.lineIndex + 1
        let line = storage.lines[li]
        let ci = characterIndex(at: x, in: line, with: f) ?? line.endIndex
        let q = CodeStoragePosition(lineIndex: li, characterIndex: ci)
        caretPosition = q
        selectionRange = q..<q
        selectionAnchorPosition = nil
    }
    mutating func moveUpAndModifySelection(font f:NSFont, at p:CGFloat) {
        var x = self
        x.moveUp(font: f, at: p)
        modifySelectionWithAnchor(to: x.caretPosition)
    }
    mutating func moveDownAndModifySelection(font f:NSFont, at p:CGFloat) {
        var x = self
        x.moveDown(font: f, at: p)
        modifySelectionWithAnchor(to: x.caretPosition)
    }
    mutating func moveToBeginningOfDocument() {
        caretPosition = startPosition
        selectionRange = startPosition..<startPosition
        selectionAnchorPosition = nil
    }
    mutating func moveToEndOfDocument() {
        caretPosition = endPosition
        selectionRange = endPosition..<endPosition
        selectionAnchorPosition = nil
    }
    mutating func moveToBeginningOfDocumentAndModifySelection() {
        var x = self
        x.moveToBeginningOfDocument()
        modifySelectionWithAnchor(to: x.caretPosition)
    }
    mutating func moveToEndOfDocumentAndModifySelection() {
        var x = self
        x.moveToEndOfDocument()
        modifySelectionWithAnchor(to: x.caretPosition)
    }
    mutating func selectAll() {
        selectionRange = startPosition..<endPosition
    }
    
    /// Inserts a new line replacing current selection.
    mutating func insertNewLine() {
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
    mutating func insertTab() {
        let tabReplacement = config.editing.makeTabReplacement()
        replaceCharactersInCurrentSelection(with: tabReplacement)
    }
    mutating func insertBacktab() {
        let line = storage.lines[caretPosition.lineIndex]
        let n = line.countPrefix(" ")
        guard n > 0 else { return }
        let m = (n - 1) / config.editing.tabSpaceCount
        let k = n - m * config.editing.tabSpaceCount
        for _ in 0..<k {
            deleteBackward()
        }
//        replaceCharactersInCurrentSelection(with: config.tabReplacement)
    }
    mutating func deleteForward() {
        if selectionRange.isEmpty { moveRightAndModifySelection() }
        replaceCharactersInCurrentSelection(with: "")
    }
    mutating func deleteBackward() {
        if selectionRange.isEmpty { moveLeftAndModifySelection() }
        replaceCharactersInCurrentSelection(with: "")
    }
    mutating func deleteToBeginningOfLine() {
        let oldSelectionRange = selectionRange
        moveToLeftEndOfLine()
        selectionRange = caretPosition..<oldSelectionRange.upperBound
        replaceCharactersInCurrentSelection(with: "")
    }
    mutating func deleteToEndOfLine() {
        let oldSelectionRange = selectionRange
        moveToRightEndOfLine()
        selectionRange = oldSelectionRange.lowerBound..<caretPosition
        replaceCharactersInCurrentSelection(with: "")
    }
}
