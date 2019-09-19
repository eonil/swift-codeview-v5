//
//  CodeLineKey.swift
//  
//
//  Created by Henry Hathaway on 9/6/19.
//

import Foundation
import BTree

public typealias CodeLineKey = Int32

struct CodeLineKeyManagement {
    private var producedKeys = 0..<0 as Range<CodeLineKey>
    private var availableKeys = 0..<CodeLineKey.max as Range<CodeLineKey>
    private var reuseQueue = SortedSet<CodeLineKey>()
    mutating func allocate() -> CodeLineKey {
        if reuseQueue.isEmpty {
            let k = availableKeys.lowerBound
            producedKeys = producedKeys.lowerBound..<producedKeys.upperBound+1
            availableKeys = availableKeys.dropFirst()
            return k
        }
        else {
            let k = reuseQueue.removeFirst()
            return k
        }
    }
    mutating func allocate(_ n:Int) -> [CodeLineKey] {
        var a = [CodeLineKey]()
        a.reserveCapacity(n)
        for _ in 0..<n {
            a.append(allocate())
        }
        return a
    }
    mutating func deallocate(_ k:CodeLineKey) {
        reuseQueue.insert(k)
    }
}

