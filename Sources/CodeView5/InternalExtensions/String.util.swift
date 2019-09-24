//
//  String.util.swift
//  
//
//  Created by Henry Hathaway on 9/7/19.
//

import Foundation
import AppKit
import CoreText

extension String {
    func contiguized() -> String {
        var s = self
        s.makeContiguousUTF8()
        return s
    }
    /// Calls `Substring.frameOfCharactersInSubrange`.
    func frameOfCharactersInUTF8OffsetSubrange(_ r:Range<Int>, withFont f:NSFont) -> CGRect {
        return allSubcontent().frameOfCharactersInUTF8OffsetSubrange(r, withFont: f)
    }
}

extension Substring {
    /// - Returns:
    ///     Frame coordinates in text's local bounding space.
    ///     This means where the text subrange is placed in the total text bounding.
    ///     Take care that height of returning frame does not fill line height.
    func frameOfCharactersInUTF8OffsetSubrange(_ r:Range<Int>, withFont f:NSFont) -> CGRect {
        let ss1 = subcontentInUTF8OffsetRange(..<r.lowerBound)
        let ss2 = subcontentInUTF8OffsetRange(r)
        let line1 = CTLine.make(with: ss1, font: f)
        let line2 = CTLine.make(with: ss2, font: f)
        let b1 = line1.__bounds
        let b2 = line2.__bounds
        return CGRect(
            x: b1.maxX,
            y: b2.minY,
            width: b2.width,
            height: b2.height)
    }
}
