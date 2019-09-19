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
public struct CodeSource: CodeSourceEditing {
    public init() {
        storage.lines.append(CodeLine())
        let p = CodeStoragePosition(lineIndex: 0, characterIndex: storage.lines.first!.startIndex)
        caretPosition = p
        selectionRange = p..<p
    }
    
    /// Unique identifier to distinguish different snapshot points.
    /// This is a monotonically incrementing number.
    public private(set) var version = 1
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
    /// Lines cannot be `lines.endIndex` becuase character-index cannot be defined
    /// for non-existing lines.
    func isValidPosition(_ p:CodeStoragePosition) -> Bool {
        let line = storage.lines[p.lineIndex]
        return storage.lines.indices.contains(p.lineIndex)
            && (line.indices.contains(p.characterIndex) || p.characterIndex == line.endIndex)
    }
//    /// Gets a new valid position that is nearest to supplied position.
//    func nearestValidPosition(_ p:CodeStoragePosition) -> CodeStoragePosition {
//        guard !isValidPosition(p) else { return p }
//        if p.lineIndex < storage.lines.count {
//            let line = storage.lines[p.lineIndex]
//            return CodeStoragePosition(lineIndex: p.lineIndex, characterIndex: line.endIndex)
//        }
//        else {
//            return endPosition
//        }
//    }
//    func nearestValidRange(_ r:Range<CodeStoragePosition>) -> Range<CodeStoragePosition> {
//        let a = nearestValidPosition(r.lowerBound)
//        let b = nearestValidPosition(r.upperBound)
//        return a..<b
//    }
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
        
        // Update breakpoint positions.
        let removeLineCount = rangeToReplace.lineRange.count
        let newLineCharCount = replacementString.filter({ $0 == "\n" }).count
        breakpointLineOffsets = Set(breakpointLineOffsets.compactMap({ i in
            if i <= rangeToReplace.lowerBound.lineIndex {
                return i
            }
            else {
                let k = i + -removeLineCount + newLineCharCount
                return k <= rangeToReplace.lowerBound.lineIndex ? nil : k
            }
        }))
        
        // Record changes.
        timeline.recordReplacement(
            base: baseSnapshot,
            in: rangeToReplace,
            with: replacementString)
        
        // Increment version.
        version += 1
        
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
