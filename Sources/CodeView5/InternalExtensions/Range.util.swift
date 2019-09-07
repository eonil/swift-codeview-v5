//
//  Range.util.swift
//  
//
//  Created by Henry Hathaway on 9/7/19.
//

import Foundation

extension Range where Bound == CodeStoragePosition {
    var lineRange: Range<Int> {
        return lowerBound.line..<upperBound.line
    }
    /// This always include ending line index.
    var includedLineRange: Range<Int> {
        return lowerBound.line..<upperBound.line+1
    }
    /// - Parameter lineIndexInStorage:
    ///     Index to a line in `CodeStorage.lines`.
    ///     This must be a valid index in `storage`. Otherwise, program crashes.
    func characterRangeOfLine(at lineIndexInStorage: Int, in storage:CodeStorage) -> Range<String.Index> {
        precondition(storage.lines.indices.contains(lineIndexInStorage))
        let content = storage.lines[lineIndexInStorage].content
        let a = lowerBound.line == lineIndexInStorage ? lowerBound.characterIndex : content.startIndex
        let b = upperBound.line == lineIndexInStorage ? upperBound.characterIndex : content.endIndex
        return a..<b
    }
}
