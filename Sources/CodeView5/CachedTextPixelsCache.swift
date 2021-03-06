//
//  File.swift
//
//
//  Created by Henry Hathaway on 9/24/19.
//

import Foundation

final class CachedTextPixelsCache {
    static let sharedLineNumberCache = CachedTextPixelsCache()
    static let sharedCodeLineCache = CachedTextPixelsCache()
    
    private let ctx = DispatchQueue(label: "CachedTextPixelsCache/Access")
    private var cachedLines = [Int: CachedTextPixels]()
    private var cacheLimit = 100
    /// - First one is the oldest accessed.
    /// - Last one is the newest accessed.
    private var accessOrder = [Int]()
    
    private func markRecentAccess(_ key:Int) {
        if let i = accessOrder.firstIndex(of: key) {
            accessOrder.remove(at: i)
            accessOrder.append(i)
        }
    }
    func find(_ key:Int) -> CachedTextPixels? {
        return ctx.sync {
            markRecentAccess(key)
            return cachedLines[key]
        }
    }
    func insert(_ line:CachedTextPixels, for key: Int) {
        return ctx.sync {
            cachedLines[key] = line
            accessOrder.append(key)
            removeOverLimitItems()
        }
    }
    private func removeOverLimitItems() {
        if accessOrder.count > cacheLimit {
            let n = accessOrder.count - cacheLimit
            let keysToDelete = accessOrder[0..<n]
            for k in keysToDelete {
                cachedLines[k] = nil
            }
            accessOrder.removeFirst(n)
        }
    }
    func removeAll() {
        ctx.sync {
            cachedLines.removeAll()
            accessOrder.removeAll()
        }
    }
}
