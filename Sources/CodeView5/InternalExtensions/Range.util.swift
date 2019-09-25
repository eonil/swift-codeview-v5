//
//  Range.util.swift
//  
//
//  Created by Henry Hathaway on 9/7/19.
//

import Foundation

extension Range where Bound == CodeStoragePosition {
    var lineOffsetRange: Range<Int> {
        return lowerBound.lineOffset..<upperBound.lineOffset
    }
    /// This always include ending line index.
    var includedLineOffsetRange: Range<Int> {
        return lowerBound.lineOffset..<upperBound.lineOffset+1
    }
    /// - Parameter lineOffsetInStorage:
    ///     Offset to a line in `CodeTextStorage.lines`.
    ///     This must be a valid index in `storage`. Otherwise, program crashes.
    func characterUTF8OffsetRangeOfLine(at lineOffsetInStorage: Int, in storage:CodeTextStorage) -> Range<Int> {
        let lineIndex = storage.lines.startIndex + lineOffsetInStorage
        precondition(storage.lines.indices.contains(lineIndex))
        let content = storage.lines[lineIndex].characters
        let a = lowerBound.lineOffset == lineOffsetInStorage ? lowerBound.characterUTF8Offset : 0
        let b = upperBound.lineOffset == lineOffsetInStorage ? upperBound.characterUTF8Offset : content.utf8.count
        return a..<b
    }
}
