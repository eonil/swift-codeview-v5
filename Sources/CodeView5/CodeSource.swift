//
//  CodeSource.swift
//  CodeView5
//
//  Created by Henry on 2019/07/31.
//  Copyright © 2019 Eonil. All rights reserved.
//

import Foundation
import BTree

/// Stores and manages semantic information of code text.
///
/// This does not store or manage any of "appearance" or "rendering" information.
/// Those stuffs should be processed by separated rendering component.
///
/// - This always keeps one line at the end.
/// - Last line is a placeholder for new text insertion and also marks for new-line character for I/O.
/// - When extporting text into single `String`, just simply join all lines with new-line character.
/// - This manages selection always consistently.
///
/// Caret & Selection
/// -----------------
/// Caret and selection exist independently.
/// End user controls caret and can control selection range.
/// Sometimes caret and selection need to be set equally due to UX reason.
/// In that case, you need to set them all. There's no automatic synchronization.
/// Renderer is supposed to hide caret if selection is non-zero length.
///
/// Most editing command moves caret and selection together.
///
public struct CodeSource {
    public init() {
        storage.lines.append(CodeLine())
    }
    
    /// Changes in config will be applied from next editing.
    public var config = CodeSourceEditingConfig()
    
    /// Assigning new storage invalidates any caret/selection and set them to default value.
    public fileprivate(set) var storage = CodeStorage()
    
    /// Caret position.
    ///
    /// This value must be in storage range.
    /// Setting an invalid position crashes program.
    public var caretPosition = CodeStoragePosition.zero {
        willSet(x) {
            precondition(isValidPosition(x))
        }
    }
    
    /// When you start selection by moving carets, this value will be set
    /// to mark starting position of the selection.
    public var selectionAnchorPosition = CodeStoragePosition?.none {
        willSet(x) {
            precondition(x == nil || isValidPosition(x!))
        }
    }
    
    /// Selected character range over multiple lines.
    ///
    /// Selection includes character at `lowerBound` and excluding character at `upperBound`.
    /// Lines of all positions must be indices to existing lines. For example, if there are two lines,
    /// maximum line index can be `1`.
    /// All positions in this value must be in storage range.
    /// Setting an invalid position crashes program.
    public var selectionRange = Range<CodeStoragePosition>(uncheckedBounds: (.zero, .zero)) {
        willSet(x) {
            precondition(isValidPosition(x.lowerBound))
            precondition(isValidPosition(x.upperBound))
        }
    }
    /// Includes range.upperBound.line
    public var selectionLineRange: Range<Int> { selectionRange.lowerBound.line..<selectionRange.upperBound.line+1 }

//    var styles = [CodeLine]()
    
    mutating func toggleBreakPoint(at line: Int) {
        storage.toggleBreakPoint(at: line)
    }
}
public extension CodeSource {
    var startPosition: CodeStoragePosition { .zero }
    var endPosition: CodeStoragePosition {
        /// `CodeSource` guarantees having one line at least always.
        CodeStoragePosition(line: storage.lines.count-1, characterIndex: storage.lines.last!.endIndex)
    }
    func isValidPosition(_ p:CodeStoragePosition) -> Bool {
        if p.line < storage.lines.count {
            let line = storage.lines[p.line]
            return p.characterIndex <= line.endIndex
        }
        else {
            return p.line == storage.lines.count && p.characterIndex == .zero
        }
    }
    /// Gets a new valid position that is nearest to supplied position.
    func nearestValidPosition(_ p:CodeStoragePosition) -> CodeStoragePosition {
        guard !isValidPosition(p) else { return p }
        if p.line < storage.lines.count {
            let line = storage.lines[p.line]
            return CodeStoragePosition(line: p.line, characterIndex: line.endIndex)
        }
        else {
            return endPosition
        }
    }
    func nearestValidRange(_ r:Range<CodeStoragePosition>) -> Range<CodeStoragePosition> {
        let a = nearestValidPosition(r.lowerBound)
        let b = nearestValidPosition(r.upperBound)
        return a..<b
    }
}
public extension CodeSource {
    private func position(after p: CodeStoragePosition) -> CodeStoragePosition {
        let line = storage.lines[p.line]
        let i = line.index(after: p.characterIndex)
        return CodeStoragePosition(line: p.line, characterIndex: i)
    }
    private func position(before p: CodeStoragePosition) -> CodeStoragePosition {
        let line = storage.lines[p.line]
        let i = line.index(before: p.characterIndex)
        return CodeStoragePosition(line: p.line, characterIndex: i)
    }
    
    /// Replaces characters in current selection.
    /// 
    /// - Parameter selection: What to select after replacement operation.
    mutating func replaceCharactersInCurrentSelection(with s:String) {
        // Update storage.
        storage.removeCharacters(in: selectionRange)
        let r = storage.insertCharacters(s, at: selectionRange.lowerBound)
        
        // Move carets and selection.
        let q = r.upperBound
        caretPosition = q
        selectionRange = q..<q
        selectionAnchorPosition = q
    }
}

//struct CodeLine {
//    var spans = [CodeSpan]()
//}
//struct CodeSpan {
//    var code = ""
//    var style = CodeStyle.plain
//}
//enum CodeStyle {
//    case plain
//    case keyword
//    case literal
//    case identifier
//}

// MARK: Edit Command
import AppKit
import CoreText
extension CodeSource {
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
        let lineIndex = caretPosition.line - 1
        let charIndex = storage.lines[lineIndex].endIndex
        caretPosition = CodeStoragePosition(line: lineIndex, characterIndex: charIndex)
        selectionRange = caretPosition..<caretPosition
        selectionAnchorPosition = nil
    }
    private mutating func moveToStartOfDownLine() {
        guard caretPosition != endPosition else { return }
        let lineIndex = caretPosition.line + 1
        let charIndex = storage.lines[lineIndex].startIndex
        caretPosition = CodeStoragePosition(line: lineIndex, characterIndex: charIndex)
        selectionRange = caretPosition..<caretPosition
        selectionAnchorPosition = nil
    }
    
    mutating func moveLeft() {
        guard caretPosition != startPosition else { return }
        let p = caretPosition
        let line = storage.lines[p.line]
        if line.startIndex < p.characterIndex {
            let i = line.index(before: p.characterIndex)
            let q = CodeStoragePosition(line: p.line, characterIndex: i)
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
        let line = storage.lines[p.line]
        if p.characterIndex < line.endIndex {
            let i = line.index(after: p.characterIndex)
            let q = CodeStoragePosition(line: p.line, characterIndex: i)
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
        let line = storage.lines[p.line]
        let q = CodeStoragePosition(line: p.line, characterIndex: line.startIndex)
        caretPosition = q
        selectionRange = q..<q
        selectionAnchorPosition = nil
    }
    mutating func moveToRightEndOfLine() {
        let p = caretPosition
        let line = storage.lines[p.line]
        let q = CodeStoragePosition(line: p.line, characterIndex: line.endIndex)
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
        guard 0 < p.line else { return }
        let li = p.line - 1
        let line = storage.lines[li]
        let ci = characterIndex(at: x, in: line, with: f) ?? line.endIndex
        let q = CodeStoragePosition(line: li, characterIndex: ci)
        caretPosition = q
        selectionRange = q..<q
        selectionAnchorPosition = nil
    }
    mutating func moveDown(font f:NSFont, at x:CGFloat) {
        let p = caretPosition
        guard p.line < storage.lines.count-1 else { return }
        let li = p.line + 1
        let line = storage.lines[li]
        let ci = characterIndex(at: x, in: line, with: f) ?? line.endIndex
        let q = CodeStoragePosition(line: li, characterIndex: ci)
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
        if config.autoIndent {
            let upLine = storage.lines[caretPosition.line-1]
            let tabReplacement = config.makeTabReplacement()
            let n = upLine.countPrefix(tabReplacement)
            for _ in 0..<n {
                replaceCharactersInCurrentSelection(with: tabReplacement)
            }
        }
    }
    mutating func insertTab() {
        let tabReplacement = config.makeTabReplacement()
        replaceCharactersInCurrentSelection(with: tabReplacement)
    }
    mutating func insertBacktab() {
        let line = storage.lines[caretPosition.line]
        let n = line.countPrefix(" ")
        guard n > 0 else { return }
        let m = (n - 1) / config.tabSpaceCount
        let k = n - m * config.tabSpaceCount
        for _ in 0..<k {
            deleteBackward()
        }
//        replaceCharactersInCurrentSelection(with: config.tabReplacement)
    }
    mutating func deleteForward() {
        moveRightAndModifySelection()
        replaceCharactersInCurrentSelection(with: "")
    }
    mutating func deleteBackward() {
        moveLeftAndModifySelection()
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

// MARK: Support Functions
private extension CodeSource {
    func characterIndex(at x:CGFloat, in line:CodeLine, with f:NSFont) -> String.Index? {
        let s = String(line.content)
        let ctline = CTLine.make(with: s, font: f)
        let utf16Offset = CTLineGetStringIndexForPosition(ctline, CGPoint(x: x, y: 0))
        guard utf16Offset != kCFNotFound else { return nil }
        return line.content.utf16.index(line.content.utf16.startIndex, offsetBy: utf16Offset)
    }
//    func printCaretAndSelection() {
//        print("caret: \(stringify(caretPosition))")
//        print("selection lower: \(stringify(selectionRange.lowerBound))")
//        print("selection upper: \(stringify(selectionRange.upperBound))")
//        if let x = selectionAnchorPosition {
//            print("selection anchor: \(stringify(x))")
//        }
//    }
//    func stringify(_ p:CodeStoragePosition) -> String {
//        let line = storage.lines[p.line]
//        let ss = line[..<p.characterIndex]
//        let chs = Array(ss)
//        return "\(chs)"
//    }
}

