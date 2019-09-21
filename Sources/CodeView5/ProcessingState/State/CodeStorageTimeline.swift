//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/19/19.
//

import Foundation

private let keyAccess = DispatchQueue(label: "CodeStorageTimeline/Key")
private var keySeed = 0 as CodeStorageTimeline.Key
private func makeKey() -> CodeStorageTimeline.Key {
    return keyAccess.sync {
        keySeed += 1
        return keySeed
    }
}

/// A timeline to track changes in a code storage.
/// - This is not for UI level undo/redo support.
/// - This is designed to provide change-sets.
public struct CodeStorageTimeline {
    public private(set) var points = [Point]()
    public struct Point {
        /// Timeline-local unique identifier to identify each point in timeline.
        /// No same key will ever be reused in a timeline.
        public var key: Key
        public var baseSnapshot: CodeStorage
        /// Range in `baseSnapshot`.
        public var replacementRange: CodeStorageRange
        public var replacementContent: String
    }
    public typealias CodeStorageRange = Range<CodeStoragePosition>
    public typealias Key = Int
    mutating func recordReplacement(base snapshot: CodeStorage, in range: CodeStorageRange, with content: String) {
        let p = Point(
            key: makeKey(),
            baseSnapshot: snapshot,
            replacementRange: range,
            replacementContent: content)
        points.append(p)
    }
    mutating func removeAll() {
        points.removeAll()
    }
}

