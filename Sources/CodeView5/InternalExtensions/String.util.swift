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
    func frameOfCharactersInSubrange(_ r:Range<String.Index>, withFont f:NSFont) -> CGRect {
        return self[startIndex...].frameOfCharactersInSubrange(r, withFont: f)
    }
}

extension Substring {
    /// - Returns:
    ///     Frame coordinates in text's local bounding space.
    ///     This means where the text subrange is placed in the total text bounding.
    ///     Take care that height of returning frame does not fill line height.
    func frameOfCharactersInSubrange(_ r:Range<String.Index>, withFont f:NSFont) -> CGRect {
        let ss1 = self[..<r.lowerBound]
        let ss2 = self[r]
        let line1 = CTLine.make(with: ss1, font: f)
        let line2 = CTLine.make(with: ss2, font: f)
        let b1 = line1.bounds
        let b2 = line2.bounds
        return CGRect(
            x: b1.maxX,
            y: b2.minY,
            width: b2.width,
            height: b2.height)
    }
}
