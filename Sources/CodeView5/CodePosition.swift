//
//  CodePosition.swift
//  CodeView5Demo
//
//  Created by Henry Hathaway on 9/4/19.
//  Copyright © 2019 Eonil. All rights reserved.
//

import Foundation

/// Selection to be used for external communication.
struct CodeSelection {
    var range = CodePosition.zero..<CodePosition.zero
}
struct CodePosition: Comparable {
    /// Offset from start in line list in storage.
    var line = 0
    /// Offset from start in characters in target line.
    /// This is number of `Character`s from start of the line.
    /// 
    /// In most cases, code line do not exceed 128 characters
    /// counting them for each time would be easier to maintain.
    ///
    /// Having extremly long line is strongly discouraged
    /// and won't work well with this view.
    ///
    /// `CodeView` also keeps whole pre-resolved indices
    /// for each columns for current line. Mapping would be
    /// trivial.
    var column = 0
    static let zero = CodePosition(line: 0, column: 0)
    static func < (_ a:CodePosition, _ b:CodePosition) -> Bool {
        if a.line == b.line {
            return a.column < b.column
        }
        else {
            return a.line < b.line
        }
    }
}
