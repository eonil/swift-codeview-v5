//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/24/19.
//

import Foundation

extension BTMap {
    subscript(_ k:Key, defaultValue v:@autoclosure() -> Value) -> Value {
        get { self[k] ?? v() }
        set(x) { self[k] = x }
    }
}
