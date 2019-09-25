//
//  Dup.swift
//  CodeView5Demo
//
//  Created by Henry Hathaway on 9/25/19.
//  Copyright © 2019 Henry Hathaway. All rights reserved.
//

import Foundation

extension RandomAccessCollection {
    func atOffset(_ offset:Int) -> Element {
        let idx = index(startIndex, offsetBy: offset)
        return self[idx]
    }
    var offsets: Range<Int> {
        return 0..<count
    }
}

extension RandomAccessCollection where Self: MutableCollection {
    mutating func set(_ e:Element, atOffset offset:Int) {
        let idx = index(startIndex, offsetBy: offset)
        self[idx] = e
    }
}

extension StringProtocol {
    /// Though it's not been documented, it is actually O(1).
    func indexFromUTF8Offset(_ utf8Offset:Int) -> Index {
        return utf8.index(utf8.startIndex, offsetBy: utf8Offset)
    }
    /// Though it's not been documented, it is actually O(1).
    func utf8OffsetFromIndex(_ index:Index) -> Int {
        return utf8.distance(from: utf8.startIndex, to: index)
    }
    /// Though it's not been documented, it is actually O(1).
    func indexRangeFromUTF8OffsetRange(_ utf8OffsetRange:Range<Int>) -> Range<String.Index> {
        let a = indexFromUTF8Offset(utf8OffsetRange.lowerBound)
        let b = indexFromUTF8Offset(utf8OffsetRange.upperBound)
        return a..<b
    }
    /// Though it's not been documented, it is actually O(1).
    func utf8OffsetRangeFromIndexRange(_ indexRange:Range<String.Index>) -> Range<Int> {
        let a = utf8OffsetFromIndex(indexRange.lowerBound)
        let b = utf8OffsetFromIndex(indexRange.upperBound)
        return a..<b
    }
    /// Though it's not been documented, it is actually O(1).
    func subcontentInUTF8OffsetRange(_ utf8OffsetRange: Range<Int>) -> SubSequence {
        let indexRange = indexRangeFromUTF8OffsetRange(utf8OffsetRange)
        return self[indexRange]
    }
    /// Though it's not been documented, it is actually O(1).
    func subcontentInUTF8OffsetRange(_ utf8OffsetRange: PartialRangeFrom<Int>) -> SubSequence {
        let fullRange = utf8OffsetRange.lowerBound..<utf8.count
        return subcontentInUTF8OffsetRange(fullRange)
    }
    /// Though it's not been documented, it is actually O(1).
    func subcontentInUTF8OffsetRange(_ utf8OffsetRange: PartialRangeUpTo<Int>) -> SubSequence {
        let fullRange = 0..<utf8OffsetRange.upperBound
        return subcontentInUTF8OffsetRange(fullRange)
    }
}
