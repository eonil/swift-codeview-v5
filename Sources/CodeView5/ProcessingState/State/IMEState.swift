//
//  IMEState.swift
//  
//
//  Created by Henry Hathaway on 9/5/19.
//

import Foundation

public struct IMEState {
    var incompleteText = ""
    var selectionInIncompleteText = "".startIndex..<"".endIndex
    var selectionInIncompleteTextAsUTF8CodeUnitOffset: Range<Int> {
        let r = selectionInIncompleteText
        let a = incompleteText.utf8.distance(from: incompleteText.utf8.startIndex, to: r.lowerBound)
        let b = incompleteText.utf8.distance(from: r.lowerBound, to: r.upperBound)
        return a..<(a+b)
    }
}
