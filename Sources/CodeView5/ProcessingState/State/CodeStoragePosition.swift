//
//  CodeStoragePosition.swift
//  CodeView5Demo
//
//  Created by Henry Hathaway on 9/5/19.
//  Copyright © 2019 Eonil. All rights reserved.
//

import Foundation

/// This uses UTF-8 code unit offset to be normalized.
/// - `String`/`Substring` indices are not stable or normalized.
/// - They can have different values after processing.
/// - That makes big headache. Unnecessary management cost.
/// - Also invalidates comparison operation.
/// - `UTF8View` performs index + distance operations in O(1).
///     - This is not yet been documented, but dev team pointed out in Swift Forum.
public struct CodeStoragePosition: Comparable {
    public var lineOffset = 0
    public var characterUTF8Offset = 0
    public static var zero: CodeStoragePosition { CodeStoragePosition(lineOffset: 0, characterUTF8Offset: 0) }
    public static func < (_ a:CodeStoragePosition, _ b:CodeStoragePosition) -> Bool {
        if a.lineOffset == b.lineOffset { return a.characterUTF8Offset < b.characterUTF8Offset }
        return a.lineOffset < b.lineOffset
    }
}
