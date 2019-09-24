//
//  CodeStorage.swift
//  CodeView5
//
//  Created by Henry on 2019/07/31.
//  Copyright © 2019 Eonil. All rights reserved.
//

import Foundation
import BTree

/// Stores and manages text and selection values of code editing state.
///
/// This contains only what content and selection is in editing.
/// This does not include how they should be "rendered".
///
/// - This always keeps one line at the end.
/// - Last line is a placeholder for new text insertion and also marks for new-line character for I/O.
/// - When exporting text as single `String`, just simply join all lines with your new-line character.
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
public struct CodeStorage: CodeStorageEditingProtocol {
    public init() {
        text.lines.append(CodeLine())
        let p = CodeStoragePosition.zero
        caretPosition = p
        selectionRange = p..<p
    }

    public private(set) var text = CodeTextStorage()
    /// Recorded changes performed on text storage.
    /// Recorded timeline points can be deleted.
    /// Do not assume empty timeline as "no-change".
    /// It only means there's "no **tracked** change".
    public private(set) var timeline = CodeTextTimeline()
    
    /// Caret position.
    ///
    /// This value must be in range of stored text.
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
    /// All positions in this value must be in range in stored text.
    /// Setting an invalid position crashes program.
    public var selectionRange: Range<CodeStoragePosition> {
        willSet(x) {
            precondition(isValidPosition(x.lowerBound))
            precondition(isValidPosition(x.upperBound))
        }
    }
}
public extension CodeStorage {
    /// Lines cannot be `lines.endIndex` becuase character-index cannot be defined
    /// for non-existing lines.
    func isValidPosition(_ p:CodeStoragePosition) -> Bool {
        guard (0..<text.lines.count).contains(p.lineOffset) else { return false }
        let lineContent = text.lines.atOffset(p.lineOffset).characters
        guard (0...lineContent.utf8.count).contains(p.characterUTF8Offset) else { return false }
        return true
    }
    func isValidRange(_ r:Range<CodeStoragePosition>) -> Bool {
        return isValidPosition(r.lowerBound) && isValidPosition(r.upperBound)
    }
}
public extension CodeStorage {
    private func position(after p: CodeStoragePosition) -> CodeStoragePosition {
        let lineIndex = text.lines.startIndex + p.lineOffset
        let line = text.lines[lineIndex]
        let charIndex = line.characters.utf8.index(line.characters.utf8.startIndex, offsetBy: p.characterUTF8Offset)
        let newCharIndex = line.characters.index(after: charIndex)
        let newCharUTF8Offset = line.characters.utf8.distance(from: line.characters.utf8.startIndex, to: newCharIndex)
        return CodeStoragePosition(lineOffset: p.lineOffset, characterUTF8Offset: newCharUTF8Offset)
    }
    private func position(before p: CodeStoragePosition) -> CodeStoragePosition {
        let lineIndex = text.lines.startIndex + p.lineOffset
        let line = text.lines[lineIndex]
        let charIndex = line.characters.utf8.index(line.characters.utf8.startIndex, offsetBy: p.characterUTF8Offset)
        let newCharIndex = line.characters.index(before: charIndex)
        let newCharUTF8Offset = line.characters.utf8.distance(from: line.characters.utf8.startIndex, to: newCharIndex)
        return CodeStoragePosition(lineOffset: p.lineOffset, characterUTF8Offset: newCharUTF8Offset)
    }
    /// You can get single string by calling `join(separator: "\n")` on returning array.
    func lineContentsInCurrentSelection() -> [Substring] {
        return text.lineContents(in: selectionRange)
    }
    /// Replaces characters in current selection.
    ///
    /// This is **the only mutator** to modify underlying **text content** of `CodeTextStorage`.
    /// Therefore, thsi can track *all* changes in **text content** correctly.
    ///
    /// - Note: Style informations can be updated independently.
    ///
    /// - Parameter selection: What to select after replacement operation.
    mutating func replaceCharactersInCurrentSelection(with s:String) {
        // Prepare.
        let baseSnapshot = text
        let rangeToReplace = selectionRange
        let replacementString = s.contiguized()
        
        // Update storage.
        let removedPosition = text.removeCharacters(in: rangeToReplace)
        let r = text.insertCharacters(replacementString, at: removedPosition)
        
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
    /// Changes styles of characters in range.
    /// **This does not make timeline entry** as this won't be considered as textual content update.
    mutating func setCharacterStyle(_ s:CodeStyle, in range:Range<CodeStoragePosition>) {
        let lineCharRanges = text.characterRangesOfLines(in: range)
        for (lineOffset, charRange) in lineCharRanges {
            var line = text.lines.atOffset(lineOffset)
            line.setCharacterStyle(s, inUTF8OffsetRange: charRange)
            text.lines.set(line, atOffset: lineOffset)
        }
    }
}

extension CodeStorage {
    /// Remove all points in timeline.
    /// You must call this method at some point to reduce memory consumption of recorded points.
    mutating func cleanTimeline() {
        timeline.removeAll()
    }
}

