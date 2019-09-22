//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/21/19.
//

import Foundation

enum KeyManagement {
    typealias Key = Int
    static func makeKey() -> Key {
        return accessQueue.sync {
            seed += 1
            return seed
        }
    }
}

private let accessQueue = DispatchQueue(label: "KeyManagement/Access")
private var seed = 0
