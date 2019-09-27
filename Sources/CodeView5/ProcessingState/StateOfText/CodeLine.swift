//
//  CodeLine.swift
//  CodeView5Demo
//
//  Created by Henry Hathaway on 9/5/19.
//  Copyright © 2019 Eonil. All rights reserved.
//

import Foundation

/// A opaque collection of stuffs for each UTF-8 code units representing a line.
///
/// This represents a collection of stuffs for each UTF-8 code units with no new-lines.
/// Character contents always must be kept to be a valid UTF-8 code unit sequence
/// to build proper Unicode string.
///
/// Collection and indexings are provided only for easy of unified position representation.
/// You actually cannot access each element through this type.
/// See individual properties to access each content.
///
///
/// Features
/// --------
/// - Ensures all characters are in UTF-8 encoded form in memory.
/// - Provides O(1) access UTF-8 encoded representation.
///
/// - Note:
///     This type is like `String`, but does not conform `StringProtocol`
///     Because it's been prohibited by Swift designers.
///
public struct CodeLine: RandomAccessCollection {
    public typealias Element = Void
    public typealias Index = Int
    public typealias SubSequence = Slice<CodeLine>
    
    /// `CodeLine` ensures this to store all characters in UTF-8 encoded form in memory.
    public private(set) var characters = Substring()
    /// - Styles matches to each UTF-8 code units at same offset.
    /// - Styles for same character must have same value.
    /// - Note:
    ///     This is very likely to contain duplicated data
    ///     that can be optimized easily.
    private(set) var characterStyles = ArraySlice<CodeStyle>()
    /// If this key is equal, contents are guaranteed to be equal.
    /// If this key is different, contents are potentially different.
    private(set) var contentEqualityKey = makeKey()
    
    public init() {}
    public init(_ s:Substring) {
        assert(s.isContiguousUTF8)
        characters = s
        characters.makeContiguousUTF8()
        assert(characters.isContiguousUTF8)
        /// Using interning can accelerate initial creation of code lines.
        characterStyles = CodeStyle.plain.repeatingSlice(count: s.utf8.count)
    }
    init(content s: Substring, characterStyles ss: ArraySlice<CodeStyle>) {
        assert(s.isContiguousUTF8)
        characters = s
        characters.makeContiguousUTF8()
        assert(characters.isContiguousUTF8)
        characterStyles = ss
    }
    
    public var count: Int { characters.utf8.count }
    public var startIndex: Int { 0 }
    public var endIndex: Int { characters.utf8.count }
    public subscript(_ i: Index) -> Void { Void() }
    public subscript(_ r: Range<Index>) -> SubSequence { Slice<CodeLine>(base: self, bounds: r) }
    public mutating func replaceSubrange<R>(_ subrange: R, with newElements: Substring) where R : RangeExpression, Index == R.Bound {
        precondition(newElements.isContiguousUTF8, "You can use only contiguous UTF-8 encoded string.")
        let q = subrange.relative(to: self)
        let insertingCharacters = newElements
        let c = characters.indexFromUTF8Offset(q.lowerBound)
        let d = characters.indexFromUTF8Offset(q.upperBound)
        characters.replaceSubrange(c..<d, with: insertingCharacters)
        characters.makeContiguousUTF8()
        assert(characters.isContiguousUTF8)
        
        characterStyles.replaceSubrange(q, with: repeatElement(.plain, count: insertingCharacters.utf8.count))
        contentEqualityKey = makeKey()
    }
    public mutating func insert(contentsOf s:Substring, at i:Index) {
        replaceSubrange(i..<i, with: s)
    }
    public mutating func append(contentsOf s:Substring) {
        insert(contentsOf: s, at: endIndex)
    }
    public mutating func setCharacterStyle(_ s:CodeStyle, inUTF8OffsetRange range:Range<Int>) {
        characterStyles.replaceSubrange(range, with: repeatElement(s, count: range.count))
        contentEqualityKey = makeKey()
    }
}


private let keyContext = DispatchQueue(label: "CodeLine/Key")
private var keySeed = 0
private func makeKey() -> Int {
    return keyContext.sync {
        keySeed += 1
        return keySeed
    }
}
