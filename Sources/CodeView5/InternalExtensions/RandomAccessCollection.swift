//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/20/19.
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
