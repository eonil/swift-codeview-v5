//
//  CodeSelection.swift
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
    var line = 0
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
