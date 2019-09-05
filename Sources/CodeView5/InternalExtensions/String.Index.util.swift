//
//  File.swift
//
//
//  Created by Henry Hathaway on 9/5/19.
//

import Foundation

extension String.Index {
    /// Start index of empty string.
    static let zero = utf8EmptyString.startIndex
}
private let utf8EmptyString = {
    var s = ""
    s.makeContiguousUTF8()
    assert(s.isContiguousUTF8)
    return s
}() as String
