//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/21/19.
//

import Foundation

public enum CodeEditingInvalidatedRegion {
    case none
    case some(bounds: CGRect)
    case all
}
