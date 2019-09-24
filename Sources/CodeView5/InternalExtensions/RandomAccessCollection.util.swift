//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/24/19.
//

import Foundation

extension RandomAccessCollection {
    func subcontentInOffsetRange(_ offsetRange:Range<Int>) -> SubSequence {
        let a = index(startIndex, offsetBy: offsetRange.lowerBound)
        let b = index(startIndex, offsetBy: offsetRange.upperBound)
        return self[a..<b]
    }
    func subcontentInOffsetRange(_ offsetRange: PartialRangeFrom<Int>) -> SubSequence {
        let fullRange = offsetRange.lowerBound..<count
        return subcontentInOffsetRange(fullRange)
    }
    /// Though it's not been documented, it is actually O(1).
    func subcontentInOffsetRange(_ offsetRange: PartialRangeUpTo<Int>) -> SubSequence {
        let fullRange = 0..<offsetRange.upperBound
        return subcontentInOffsetRange(fullRange)
    }

}
