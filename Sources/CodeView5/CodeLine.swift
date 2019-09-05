//
//  CodeLine.swift
//  CodeView5Demo
//
//  Created by Henry Hathaway on 9/5/19.
//  Copyright © 2019 Eonil. All rights reserved.
//

import Foundation

struct CodeLine: BidirectionalCollection, RangeReplaceableCollection {
    typealias Element = Character
    typealias Index = String.Index
    typealias SubSequence = String.SubSequence
    
    private(set) var utf8Characters = ""
    private(set) var precomputedCharacterCount = 0
    private(set) var precomputedUTF16CodeUnitCount = 0

    init() {
    }
    init(_ s:String) {
        utf8Characters = s
        utf8Characters.makeContiguousUTF8()
        assert(utf8Characters.isContiguousUTF8)
        precomputedCharacterCount = s.count
        precomputedUTF16CodeUnitCount = s.utf16.count
    }
    init(utf8Characters s: String, precomputedCharacterCount cc: Int, precomputedUTF16CodeUnitCount utf16uc: Int) {
        utf8Characters = s
        utf8Characters.makeContiguousUTF8()
        assert(utf8Characters.isContiguousUTF8)
        precomputedCharacterCount = cc
        precomputedUTF16CodeUnitCount = utf16uc
    }
    var startIndex: String.Index { utf8Characters.utf8.startIndex }
    var endIndex: String.Index { utf8Characters.utf8.endIndex }
    func index(after i: String.Index) -> String.Index { utf8Characters.utf8.index(after: i) }
    func index(before i: String.Index) -> String.Index { utf8Characters.utf8.index(before: i) }
    subscript(_ i: String.Index) -> Character { utf8Characters[i] }
    subscript(_ r: Range<String.Index>) -> Substring { utf8Characters[r] }
    mutating func replaceSubrange<C, R>(_ subrange: R, with newElements: C) where C : Collection, R : RangeExpression, Element == C.Element, Index == R.Bound {
        let removingCharacters = utf8Characters[subrange]
        let removingCharacterCount = removingCharacters.count
        let removingUTF16CodeUnitCount = removingCharacters.utf16.count
        let insertingCharacters = String(makingContiguousUTF8: newElements)
        let insertingCharacterCount = insertingCharacters.count
        let insertingUTF16CodeUnitCount = insertingCharacters.utf16.count
        utf8Characters.replaceSubrange(subrange, with: insertingCharacters)
        utf8Characters.makeContiguousUTF8()
        assert(utf8Characters.isContiguousUTF8)
        precomputedCharacterCount += -removingCharacterCount + insertingCharacterCount
        precomputedUTF16CodeUnitCount += -removingUTF16CodeUnitCount + insertingUTF16CodeUnitCount
    }
    
//    /// UTF-8 code unit offset based index.
//    struct Index1: Comparable {
//        let utf8Offset: Int
//    }
}

private extension String {
    init<C>(makingContiguousUTF8 s:C) where C:Collection, C.Element == Character {
        self = String(s)
        makeContiguousUTF8()
        assert(isContiguousUTF8)
    }
}
