//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/24/19.
//

import Foundation

extension Collection {
    func allSubcontent() -> SubSequence {
        return self[startIndex..<endIndex]
    }
}
