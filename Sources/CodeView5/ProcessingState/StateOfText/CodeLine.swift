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
    public typealias Index = Substring.Index
    public typealias SubSequence = Substring.SubSequence
    
    /// `CodeLine` ensures this to store all characters in UTF-8 encoded form in memory.
    public private(set) var content = Substring()
    private(set) var precomputedCharacterCount = 0
    /// - Styles matches to each UTF-8 code units at same offset.
    /// - Styles for same character must have same value.
    /// - Note:
    ///     This is very likely to contain duplicated data
    ///     that can be optimized easily.
    private(set) var characterStyles = ArraySlice<CodeStyle>()
    
    public init() {}
    public init(_ s:Substring) {
        let c = s.count
        content = s
        content.makeContiguousUTF8()
        assert(content.isContiguousUTF8)
        precomputedCharacterCount = c
        /// Using interning can accelerate initial creation of code lines.
        characterStyles = CodeStyle.plain.repeatingSlice(count: s.utf8.count)
    }
    init(content s: Substring, precomputedCharacterCount cc: Int, characterStyles ss: ArraySlice<CodeStyle>) {
        content = s
        content.makeContiguousUTF8()
        assert(content.isContiguousUTF8)
        precomputedCharacterCount = cc
        characterStyles = ss
    }
    
    public var count: Int { precomputedCharacterCount }
    public var startIndex: Index { content.startIndex }
    public var endIndex: Index { content.endIndex }
    public func index(after i: Index) -> Index { content.index(after: i) }
    public func index(before i: Index) -> Index { content.index(before: i) }
    public subscript(_ i: Index) -> Character { content[i] }
    public subscript(_ r: Range<Index>) -> SubSequence { content[r] }
    public mutating func replaceSubrange<C, R>(_ subrange: R, with newElements: C) where C : Collection, R : RangeExpression, Element == C.Element, Index == R.Bound {
        let q = subrange.relative(to: content)
        let a = content.utf8.distance(from: content.startIndex, to: q.lowerBound)
        let b = content.utf8.distance(from: content.startIndex, to: q.upperBound)
        
        let removingCharacters = content[subrange]
        let removingCharacterCount = removingCharacters.count
        let insertingCharacters = String(newElements).contiguized()
        let insertingCharacterCount = insertingCharacters.count
        content.replaceSubrange(subrange, with: insertingCharacters)
        content.makeContiguousUTF8()
        assert(content.isContiguousUTF8)
        precomputedCharacterCount += -removingCharacterCount + insertingCharacterCount
        
        characterStyles.replaceSubrange(a..<b, with: repeatElement(.plain, count: insertingCharacters.utf8.count))
    }
    public mutating func setCharacterStyle(_ s:CodeStyle, inUTF8OffsetRange range:Range<Int>) {
        characterStyles.replaceSubrange(range, with: repeatElement(s, count: range.count))
    }
}

