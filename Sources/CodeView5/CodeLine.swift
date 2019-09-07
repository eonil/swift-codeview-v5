//
//  CodeLine.swift
//  CodeView5Demo
//
//  Created by Henry Hathaway on 9/5/19.
//  Copyright © 2019 Eonil. All rights reserved.
//

import Foundation

/// A opque collection of characters representing a line.
///
/// Features
/// --------
/// - Ensures all characters are in UTF-8 encoded form in memory.
/// - Provides O(1) access UTF-8 encoded representation.
/// - Provides O(1) access to `Character` count.
/// - Provides O(1) access to UTF-16 code unit count.
///
/// - Note:
///     This type is like `String`, but does not conform `StringProtocol`
///     Because it's been prohibited by Swift designers.
///
public struct CodeLine: BidirectionalCollection, RangeReplaceableCollection {
    public typealias Element = Character
    public typealias Index = String.Index
    public typealias SubSequence = String.SubSequence
    
    /// `CodeLine` ensures this to store all characters in UTF-8 encoded form in memory.
    public private(set) var content = ""
    private(set) var precomputedCharacterCount = 0
    private(set) var precomputedUTF16CodeUnitCount = 0
    /// Styles matches to each character at same offset.
    private(set) var characterStyles = [CodeStyle]()
    
    public init() {}
    public init(_ s:String) {
        let c = s.count
        content = s
        content.makeContiguousUTF8()
        assert(content.isContiguousUTF8)
        precomputedCharacterCount = c
        precomputedUTF16CodeUnitCount = s.utf16.count
        characterStyles = Array(repeatElement(.plain, count: c))
    }
    init(content s: String, precomputedCharacterCount cc: Int, precomputedUTF16CodeUnitCount utf16uc: Int, characterStyles ss: [CodeStyle]) {
        content = s
        content.makeContiguousUTF8()
        assert(content.isContiguousUTF8)
        precomputedCharacterCount = cc
        precomputedUTF16CodeUnitCount = utf16uc
        characterStyles = ss
    }
    
    public var count: Int { precomputedCharacterCount }
    public var startIndex: String.Index { content.startIndex }
    public var endIndex: String.Index { content.endIndex }
    public func index(after i: String.Index) -> String.Index { content.index(after: i) }
    public func index(before i: String.Index) -> String.Index { content.index(before: i) }
    public subscript(_ i: String.Index) -> Character { content[i] }
    public subscript(_ r: Range<String.Index>) -> Substring { content[r] }
    public mutating func replaceSubrange<C, R>(_ subrange: R, with newElements: C) where C : Collection, R : RangeExpression, Element == C.Element, Index == R.Bound {
        let removingCharacters = content[subrange]
        let removingCharacterCount = removingCharacters.count
        let removingUTF16CodeUnitCount = removingCharacters.utf16.count
        let insertingCharacters = String(makingContiguousUTF8: newElements)
        let insertingCharacterCount = insertingCharacters.count
        let insertingUTF16CodeUnitCount = insertingCharacters.utf16.count
        content.replaceSubrange(subrange, with: insertingCharacters)
        content.makeContiguousUTF8()
        assert(content.isContiguousUTF8)
        precomputedCharacterCount += -removingCharacterCount + insertingCharacterCount
        precomputedUTF16CodeUnitCount += -removingUTF16CodeUnitCount + insertingUTF16CodeUnitCount
        let q = subrange.relative(to: content)
        let a = content.distance(from: content.startIndex, to: q.lowerBound)
        let b = content.distance(from: q.lowerBound, to: q.upperBound)
        characterStyles.replaceSubrange(a..<(a+b), with: repeatElement(.plain, count: insertingCharacterCount))
    }
}

extension CodeLine {
    func countPrefix(_ ch:Character) -> Int {
        var c = 0
        for ch1 in content {
            if ch1 == ch { c += 1 }
            else { break }
        }
        return c
    }
    func countPrefix(_ s:String) -> Int {
        let chc = s.count
        var c = 0
        var ss = content[content.startIndex...]
        while ss.hasPrefix(s) {
            ss = ss.dropFirst(chc)
            c += 1
        }
        return c
    }
}

private extension String {
    init<C>(makingContiguousUTF8 s:C) where C:Collection, C.Element == Character {
        self = String(s)
        makeContiguousUTF8()
        assert(isContiguousUTF8)
    }
}
