//
//  CodeStorageSelection.swift
//  CodeView5Demo
//
//  Created by Henry Hathaway on 9/5/19.
//  Copyright © 2019 Eonil. All rights reserved.
//

import Foundation

struct CodeStorageSelection {
    var range = Range<CodeStoragePosition>(uncheckedBounds: (lower: .zero, upper: .zero))
    /// Includes range.upperBound.line
    var lineRange: Range<Int> { range.lowerBound.line..<range.upperBound.line+1 }
    var isEmpty: Bool {
        return range.lowerBound == range.upperBound
    }
}
struct CodeStoragePosition: Comparable {
    var line: Int
    /// This index is based on string content in target line.
    var characterIndex: String.Index
    static var zero: CodeStoragePosition { CodeStoragePosition(line: .zero, characterIndex: .zero) }
    static func < (_ a:CodeStoragePosition, _ b:CodeStoragePosition) -> Bool {
        if a.line == b.line { return a.characterIndex < b.characterIndex }
        return a.line < b.line
    }
}
