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
        let p = CodeStoragePosition(lineIndex: 0, characterIndex: storage.lines.first!.startIndex)
        caretPosition = p
        selectionRange = p..<p
    }
    
    /// Changes in config will be applied from next editing.
    public var config = CodeSourceConfig()
    
    /// Unique identifier to distinguish different snapshot points.
    /// This is monotonically incrementing number.
    public private(set) var version = 1
    
    /// Assigning new storage invalidates any caret/selection and set them to default value.
    public private(set) var storage = CodeStorage() {
        didSet {
            version += 1
        }
    }
    
    /// Caret position.
    ///
    /// This value must be in storage range.
    /// Setting an invalid position crashes program.
    public var caretPosition: CodeStoragePosition {
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
    public var selectionRange: Range<CodeStoragePosition> {
        willSet(x) {
            precondition(isValidPosition(x.lowerBound))
            precondition(isValidPosition(x.upperBound))
        }
    }

    /// - Note:
    ///     You have to use only valid line offsets.
    /// - TODO: Optimize this.
    /// Need to be optimized.
    /// This would be okay for a while as most people do not install
    /// too many break-points. But if there are more than 100 break-points,
    /// this is very likely to make problems.
    public var breakpointLineOffsets = Set<Int>() {
        willSet(x) {
            let s = storage
            precondition(x.lazy.map({ s.lines.indices.contains($0) }).reduce(true, { $0 && $1 }))
        }
    }
}
public extension CodeSource {
    var startPosition: CodeStoragePosition {
        CodeStoragePosition(lineIndex: 0, characterIndex: storage.lines.first!.startIndex)
    }
    var endPosition: CodeStoragePosition {
        /// `CodeSource` guarantees having one line at least always.
        CodeStoragePosition(lineIndex: storage.lines.count-1, characterIndex: storage.lines.last!.endIndex)
    }
    /// Lines cannot be `lines.endIndex` becuase character-index cannot be defined
    /// for non-existing lines.
    func isValidPosition(_ p:CodeStoragePosition) -> Bool {
        let line = storage.lines[p.lineIndex]
        return storage.lines.indices.contains(p.lineIndex)
            && (line.indices.contains(p.characterIndex) || p.characterIndex == line.endIndex)
    }
    /// Gets a new valid position that is nearest to supplied position.
    func nearestValidPosition(_ p:CodeStoragePosition) -> CodeStoragePosition {
        guard !isValidPosition(p) else { return p }
        if p.lineIndex < storage.lines.count {
            let line = storage.lines[p.lineIndex]
            return CodeStoragePosition(lineIndex: p.lineIndex, characterIndex: line.endIndex)
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
        let line = storage.lines[p.lineIndex]
        let i = line.index(after: p.characterIndex)
        return CodeStoragePosition(lineIndex: p.lineIndex, characterIndex: i)
    }
    private func position(before p: CodeStoragePosition) -> CodeStoragePosition {
        let line = storage.lines[p.lineIndex]
        let i = line.index(before: p.characterIndex)
        return CodeStoragePosition(lineIndex: p.lineIndex, characterIndex: i)
    }
    
    func charactersInCurrentSelection() -> String {
        return storage.characters(in: selectionRange)
    }
    /// Replaces characters in current selection.
    /// 
    /// - Parameter selection: What to select after replacement operation.
    mutating func replaceCharactersInCurrentSelection(with s:String) {
        // Update storage.
        let removedPosition = storage.removeCharacters(in: selectionRange)
        let r = storage.insertCharacters(s, at: removedPosition)
        
        // Update breakpoint positions.
        let removeLineCount = selectionRange.lineRange.count
        let newLineCharCount = s.filter({ $0 == "\n" }).count
        breakpointLineOffsets = Set(breakpointLineOffsets.compactMap({ i in
            if i <= selectionRange.lowerBound.lineIndex {
                return i
            }
            else {
                let k = i + -removeLineCount + newLineCharCount
                return k <= selectionRange.lowerBound.lineIndex ? nil : k
            }
        }))
        
        // Move carets and selection.
        let q = r.upperBound
        caretPosition = q
        selectionRange = q..<q
        selectionAnchorPosition = q
    }
}

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

// MARK: Support Functions
private extension CodeSource {
    func characterIndex(at x:CGFloat, in line:CodeLine, with f:NSFont) -> String.Index? {
        let ctline = CTLine.make(with: line.content, font: f)
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

// MARK: BreakPoint Editing
extension CodeSource {
    mutating func toggleBreakPoint(at lineIndex: Int) {
        if breakpointLineOffsets.contains(lineIndex) {
            breakpointLineOffsets.remove(lineIndex)
        }
        else {
            breakpointLineOffsets.insert(lineIndex)
        }
    }
    mutating func insertBreakPoint(at lineIndex: Int)  {
        breakpointLineOffsets.insert(lineIndex)
    }
    mutating func removeBreakPoint(for lineIndex: Int) {
        breakpointLineOffsets.remove(lineIndex)
    }
}
