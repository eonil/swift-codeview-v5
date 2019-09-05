//
//  CodeStorageSelection.swift
//  CodeView5Demo
//
//  Created by Henry Hathaway on 9/5/19.
//  Copyright © 2019 Eonil. All rights reserved.
//

import Foundation

public struct CodeStoragePosition: Comparable {
    public var line: Int
    /// This index is based on string content in target line.
    public var characterIndex: String.Index
    public static var zero: CodeStoragePosition { CodeStoragePosition(line: .zero, characterIndex: .zero) }
    public static func < (_ a:CodeStoragePosition, _ b:CodeStoragePosition) -> Bool {
        if a.line == b.line { return a.characterIndex < b.characterIndex }
        return a.line < b.line
    }
}
