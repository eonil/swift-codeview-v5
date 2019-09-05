//
//  CodeSource.swift
//  CodeView5
//
//  Created by Henry on 2019/07/31.
//  Copyright © 2019 Eonil. All rights reserved.
//

import Foundation

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
struct CodeSource {
    /// Assigning new storage invalidates any caret/selection and set them to default value.
    fileprivate(set) var storage = CodeStorage()
    /// Assigning invalid position crashes program.
    var caretPosition = CodeStoragePosition.zero {
        willSet(x) {
            precondition(isValidPosition(x))
        }
    }
    
    fileprivate(set) var storageSelection = CodeStorageSelection()
        
    /// Assigning invalid position crashes program.
    var selectionRange = Range<CodeStoragePosition>(uncheckedBounds: (.zero, .zero)) {
        willSet(x) {
            precondition(isValidPosition(x.lowerBound))
            precondition(isValidPosition(x.upperBound))
        }
    }
//    var styles = [CodeLine]()
    init() {
        storage.lines.append(CodeLine())
    }
    var startPosition: CodeStoragePosition { .zero }
    var endPosition: CodeStoragePosition { CodeStoragePosition(line: storage.lines.endIndex, characterIndex: .zero) }
    func isValidPosition(_ p:CodeStoragePosition) -> Bool {
        guard p.line < storage.lines.count else { return false }
        let line = storage.lines[p.line]
        guard p.characterIndex < line.endIndex else { return false }
        return true
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
extension CodeSource {
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
    
    /// - Parameter selection: What to select after replacement operation.
    mutating func replaceCharactersInCurrentSelection(with s:String, selection: SelectionReplacement) {
        // Update storage.
        storage.removeCharacters(in: storageSelection.range)
        let r = storage.insertCharacters(s, at: storageSelection.range.lowerBound)
        // Always keep one line at least.
        if storage.lines.isEmpty {
            storage.lines.append(CodeLine())
        }
        // Move selection.
        switch selection {
        case .atStartingOfReplacementCharactersWithZeroLength:
            storageSelection.range = r.lowerBound..<r.lowerBound
        case .atEndOfReplacementCharactersWithZeroLength:
            storageSelection.range = r.upperBound..<r.upperBound
        case .allOfReplacementCharacters:
            storageSelection.range = r.lowerBound..<r.upperBound
        }
    }
    enum SelectionReplacement {
        case atStartingOfReplacementCharactersWithZeroLength
        case atEndOfReplacementCharactersWithZeroLength
        case allOfReplacementCharacters
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
    mutating func moveLeft() {
        let p = storageSelection.range.lowerBound
        let line = storage.lines[p.line]
        guard line.startIndex < p.characterIndex else { return }
        let i = line.index(before: p.characterIndex)
        let q = CodeStoragePosition(line: p.line, characterIndex: i)
        storageSelection.range = q..<q
    }
    mutating func moveRight() {
        let p = storageSelection.range.upperBound
        let line = storage.lines[p.line]
        guard p.characterIndex < line.endIndex else { return }
        let i = line.index(after: p.characterIndex)
        let q = CodeStoragePosition(line: p.line, characterIndex: i)
        storageSelection.range = q..<q
    }
    mutating func moveLeftAndModifySelection() {
        let p = storageSelection.range.lowerBound
        let line = storage.lines[p.line]
        guard line.startIndex < p.characterIndex else { return }
        let i = line.index(before: p.characterIndex)
        let q = CodeStoragePosition(line: p.line, characterIndex: i)
        storageSelection.range = q..<storageSelection.range.upperBound
    }
    mutating func moveRightAndModifySelection() {
        let p = storageSelection.range.upperBound
        let line = storage.lines[p.line]
        guard p.characterIndex < line.endIndex else { return }
        let i = line.index(after: p.characterIndex)
        let q = CodeStoragePosition(line: p.line, characterIndex: i)
        storageSelection.range = storageSelection.range.lowerBound..<q
    }
    mutating func moveToLeftEndOfLine() {
        let p = storageSelection.range.upperBound
        let line = storage.lines[p.line]
        let q = CodeStoragePosition(line: p.line, characterIndex: line.startIndex)
        storageSelection.range = q..<q
    }
    mutating func moveToRightEndOfLine() {
        let p = storageSelection.range.upperBound
        let line = storage.lines[p.line]
        let q = CodeStoragePosition(line: p.line, characterIndex: line.endIndex)
        storageSelection.range = q..<q
    }
    mutating func moveUp(font f: NSFont, at x: CGFloat) {
        let p = storageSelection.range.lowerBound
        guard 0 < p.line else { return }
        let li = p.line - 1
        let line = storage.lines[li]
        guard let ci = characterIndex(at: x, in: line, with: f) else { return }
        let q = CodeStoragePosition(line: li, characterIndex: ci)
        storageSelection.range = q..<q
    }
    mutating func moveDown(font f: NSFont, at x: CGFloat) {
        let p = storageSelection.range.upperBound
        guard p.line < storage.lines.count-1 else { return }
        let li = p.line + 1
        let line = storage.lines[li]
        guard let ci = characterIndex(at: x, in: line, with: f) else { return }
        let q = CodeStoragePosition(line: li, characterIndex: ci)
        storageSelection.range = q..<q
    }
    
    /// Inserts a new line replacing current selection.
    mutating func insertNewLine() {
        replaceCharactersInCurrentSelection(with: "\n", selection: .atEndOfReplacementCharactersWithZeroLength)
    }
    /// Implementation
    /// --------------
    /// Basic implementation strategy is;
    /// 1. Expand selection by one character before if selection is empty.
    /// 2. Delete selection.
    mutating func deleteBackward() {
        if storageSelection.range.isEmpty {
            // Expand selection to one character before.
            let p = storageSelection.range.lowerBound
            // If current character is at start position, select last of last line.
            // Otherwise, just expand to last character.
            if p.characterIndex == .zero {
                // If current line is the first line, do not expand.
                // It effectively makes this operations as no-op.
                // Otherwise, just expand to last of last line.
                if p.line == 0 {
                }
                else {
                    let p0LineIndex = p.line - 1
                    let p0CharIndex = storage.lines[p0LineIndex].endIndex
                    let p0 = CodeStoragePosition(line: p0LineIndex, characterIndex: p0CharIndex)
                    let p1 = storageSelection.range.upperBound
                    storageSelection.range = p0..<p1
                }
            }
            else {
                let line = storage.lines[p.line]
                let preidx = line.index(before: p.characterIndex)
                storageSelection.range = CodeStoragePosition(line: p.line, characterIndex: preidx)..<storageSelection.range.upperBound
            }
        }
        // Delete selection.
        replaceCharactersInCurrentSelection(with: "", selection: .allOfReplacementCharacters)
    }
    
    mutating func selectAll() {
        if storage.lines.isEmpty {
            let p = CodeStoragePosition.zero
            storageSelection.range = p..<p
        }
        else {
            let p0 = CodeStoragePosition(line: 0, characterIndex: .zero)
            let p1 = CodeStoragePosition(line: storage.lines.count-1, characterIndex: storage.lines.last!.endIndex)
            storageSelection.range = p0..<p1
        }
    }
}

// MARK: Support Functions
extension CodeSource {
    func characterIndex(at x:CGFloat, in line:CodeLine, with f:NSFont) -> String.Index? {
        let s = String(line.utf8Characters)
        let ctline = CTLine.make(with: s, font: f)
        let utf16Offset = CTLineGetStringIndexForPosition(ctline, CGPoint(x: x, y: 0))
        guard utf16Offset != kCFNotFound else { return nil }
        return line.utf8Characters.utf16.index(line.utf8Characters.startIndex, offsetBy: utf16Offset)
    }
}
