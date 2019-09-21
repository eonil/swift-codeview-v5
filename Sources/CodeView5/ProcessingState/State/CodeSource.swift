//
//  CodeSource.swift
//  CodeView5
//
//  Created by Henry on 2019/07/31.
//  Copyright © 2019 Eonil. All rights reserved.
//

import Foundation
import BTree

/// Stores and manages textual information of code text.
///
/// This does not store or manage any of "rendering" information.
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
public struct CodeSource: CodeSourceEditing {
    public init() {
        storage.lines.append(CodeLine())
        let p = CodeStoragePosition.zero
        caretPosition = p
        selectionRange = p..<p
    }
    
    /// Assigning new storage invalidates any caret/selection and set them to default value.
    public private(set) var storage = CodeStorage()
    /// Recorded changes performed on this `CodeSource`.
    /// Owner of `CodeSource` instance can delete some recordings time-to-time.
    /// Do not assume empty timeline as "no-change".
    /// It only means there's "no **tracked** change".
    public private(set) var timeline = CodeStorageTimeline()
    
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
}
public extension CodeSource {
    /// Lines cannot be `lines.endIndex` becuase character-index cannot be defined
    /// for non-existing lines.
    func isValidPosition(_ p:CodeStoragePosition) -> Bool {
        guard (0..<storage.lines.count).contains(p.lineOffset) else { return false }
        let lineContent = storage.lines.atOffset(p.lineOffset).content
        guard (0...lineContent.utf8.count).contains(p.characterUTF8Offset) else { return false }
        return true
    }
    func isValidRange(_ r:Range<CodeStoragePosition>) -> Bool {
        return isValidPosition(r.lowerBound) && isValidPosition(r.upperBound)
    }
}
public extension CodeSource {
    private func position(after p: CodeStoragePosition) -> CodeStoragePosition {
        let lineIndex = storage.lines.startIndex + p.lineOffset
        let line = storage.lines[lineIndex]
        let charIndex = line.content.utf8.index(line.content.utf8.startIndex, offsetBy: p.characterUTF8Offset)
        let newCharIndex = line.content.index(after: charIndex)
        let newCharUTF8Offset = line.content.utf8.distance(from: line.content.utf8.startIndex, to: newCharIndex)
        return CodeStoragePosition(lineOffset: p.lineOffset, characterUTF8Offset: newCharUTF8Offset)
    }
    private func position(before p: CodeStoragePosition) -> CodeStoragePosition {
        let lineIndex = storage.lines.startIndex + p.lineOffset
        let line = storage.lines[lineIndex]
        let charIndex = line.content.utf8.index(line.content.utf8.startIndex, offsetBy: p.characterUTF8Offset)
        let newCharIndex = line.content.index(before: charIndex)
        let newCharUTF8Offset = line.content.utf8.distance(from: line.content.utf8.startIndex, to: newCharIndex)
        return CodeStoragePosition(lineOffset: p.lineOffset, characterUTF8Offset: newCharUTF8Offset)
    }
    /// You can get single string by calling `join(separator: "\n")` on returning array.
    func lineContentsInCurrentSelection() -> [Substring] {
        return storage.lineContents(in: selectionRange)
    }
    /// Replaces characters in current selection.
    ///
    /// This is **the only mutator** to modify underlying `CodeStorage`.
    ///
    /// - Parameter selection: What to select after replacement operation.
    mutating func replaceCharactersInCurrentSelection(with s:String) {
        // Prepare.
        let baseSnapshot = storage
        let rangeToReplace = selectionRange
        let replacementString = s.contiguized()
        
        // Update storage.
        let removedPosition = storage.removeCharacters(in: rangeToReplace)
        let r = storage.insertCharacters(replacementString, at: removedPosition)
        
        // Record changes.
        timeline.recordReplacement(
            base: baseSnapshot,
            in: rangeToReplace,
            with: replacementString)
        
        // Move carets and selection.
        let q = r.upperBound
        caretPosition = q
        selectionRange = q..<q
        selectionAnchorPosition = q
    }
}

extension CodeSource {
    /// Remove all points in timeline.
    /// You must call this method at some point to reduce memory consumption of recorded points.
    mutating func cleanTimeline() {
        timeline.removeAll()
    }
}

