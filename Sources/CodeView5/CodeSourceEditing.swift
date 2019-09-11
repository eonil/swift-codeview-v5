//
//  CodeSourceEditing.swift
//  
//
//  Created by Henry Hathaway on 9/11/19.
//

import Foundation

/// Represents an editable code source.
protocol CodeSourceEditing {
    mutating func replaceCharactersInCurrentSelection(with s:String)
}
extension CodeSourceEditing {
    
}
