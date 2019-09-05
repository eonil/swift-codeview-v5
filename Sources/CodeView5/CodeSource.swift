//
//  CodeSource.swift
//  CodeView5
//
//  Created by Henry on 2019/07/31.
//  Copyright © 2019 Eonil. All rights reserved.
//

import Foundation

///
/// - This always keeps one line at the end.
/// - Last line is a placeholder for new text insertion and also marks for new-line character for I/O.
/// - When extporting text into single `String`, just simply join all lines with new-line character.
/// - This manages selection always consistently.
///
struct CodeSource {
    fileprivate(set) var storage = CodeStorage()
//    fileprivate(set) var selection = CodeSelection()
    fileprivate(set) var storageSelection = CodeStorageSelection()
//    var styles = [CodeLine]()
    
//    fileprivate(set) var sourceSelection: CodeSourceSelection { CodeSourceSelection(baseStorage: storage, baseStorageSelection: storageSelection) }
    
    init() {
        storage.lines.append(CodeLine())
    }
}
extension CodeSource {
    private mutating func prepareInitialLineIfNeeded() {
        guard storage.lines.isEmpty else { return }
        storage.lines.append(CodeLine())
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
