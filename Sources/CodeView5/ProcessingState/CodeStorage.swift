//
//  IMPLStringCore.swift
//  CodeView5Demo
//
//  Created by Henry Hathaway on 9/2/19.
//  Copyright © 2019 Eonil. All rights reserved.
//

import Foundation
import BTree
import SBTL
import CodeView5CustomNSString

public struct CodeStorage {
//    /// Unique keys for each lines.
//    /// This is unique only in current storage scope.
//    private var lineKeyList = List<CodeLineKey>()
//    /// Line unique key manager.
//    private var lineKeyManagement = CodeLineKeyManagement()
    
    private var implLines = List<CodeLine>()
    
    public init() {}
//    /// All keys in this storage for each lines at same indices.
//    public var keys: Keys {
//        get { Keys(of: self) }
//        set(x) { self = x.core }
//    }
//    public struct Keys: RandomAccessCollection {
//        fileprivate private(set) var core: CodeStorage
//        public init() { core = CodeStorage() }
//        public init(of c: CodeStorage) { core = c }
//        public var startIndex: Int { 0 }
//        public var endIndex: Int { core.lineCharacterCountList.count }
//        public subscript(_ i:Int) -> CodeLineKey { core.lineKeyList[i] }
//    }
    /// All lines in this storage.
    public var lines: Lines {
        get { Lines(of: self) }
        set(x) { self = x.core }
    }
    public struct Lines: RandomAccessCollection, MutableCollection, RangeReplaceableCollection {
        fileprivate private(set) var core: CodeStorage
        public init() { core = CodeStorage() }
        public init(of c: CodeStorage) { core = c }
        public var startIndex: Int { 0 }
        public var endIndex: Int { core.implLines.count }
        public subscript(_ i:Int) -> CodeLine {
            get { core.implLines[i] }
            set(x) { core.implLines[i] = x }
        }
        public mutating func replaceSubrange<C, R>(_ subrange: R, with newElements: C) where C : Collection, R : RangeExpression, Element == C.Element, Index == R.Bound {
//            /// Update keys.
//            let q = subrange.relative(to: self)
//            for k in core.lineKeyList[q] { core.lineKeyManagement.deallocate(k) }
//            core.lineKeyList.removeSubrange(q)
//            let newKeys = core.lineKeyManagement.allocate(newElements.count)
//            core.lineKeyList.insert(contentsOf: newKeys, at: q.lowerBound)
            
            /// Update contents.
            core.implLines.replaceSubrange(subrange, with: newElements)
        }
    }
}

// MARK: Editing
extension CodeStorage {
//    @available(*, deprecated: 0)
//    func characters(in range: Range<CodeStoragePosition>) -> String {
//        guard !range.isEmpty else { return "" }
//        switch range.includedLineRange.count {
//        case 0:
//            return ""
//        case 1:
//            let lineIndex = range.lowerBound.lineIndex
//            let charRange = range.characterRangeOfLine(at: lineIndex, in: self)
//            return String(lines[lineIndex].content[charRange])
//        default:
//            var sss = [Substring]()
//            for lineIndex in range.includedLineRange {
//                let charRange = range.characterRangeOfLine(at: lineIndex, in: self)
//                sss.append(lines[lineIndex].content[charRange])
//            }
//            return sss.joined(separator: "\n")
//        }
//    }
    /// You can get single string by calling `join(separator: "\n")` on returning array.
    func lineContents(in range: Range<CodeStoragePosition>) -> [Substring] {
        guard !range.isEmpty else { return [Substring()] }
        switch range.includedLineRange.count {
        case 0:
            return [Substring()]
        case 1:
            let lineIndex = range.lowerBound.lineIndex
            let charRange = range.characterRangeOfLine(at: lineIndex, in: self)
            return [lines[lineIndex].content[charRange]]
        default:
            var sss = [Substring]()
            for lineIndex in range.includedLineRange {
                let charRange = range.characterRangeOfLine(at: lineIndex, in: self)
                sss.append(lines[lineIndex].content[charRange])
            }
            return sss
        }
    }
    /// - Returns:
    ///     Position where the characters removed.
    ///     Beware that character index is based on current line's content.
    mutating func removeCharacters(in range: Range<CodeStoragePosition>) -> CodeStoragePosition {
        guard !range.isEmpty else { return range.upperBound }
        let firstLineIndex = range.lowerBound.lineIndex
        let firstLineChars = lines[firstLineIndex][..<range.lowerBound.characterIndex]
        let lastLineIndex = range.upperBound.lineIndex
        let lastLineChars = lines[lastLineIndex][range.upperBound.characterIndex...]
        lines.removeSubrange(firstLineIndex...lastLineIndex)
        var newContent = firstLineChars
        newContent.append(contentsOf: lastLineChars)
        lines.insert(CodeLine(newContent), at: firstLineIndex)
        
        // Slow path.
        let charCount = firstLineChars.count
        let charIndex = newContent.index(newContent.startIndex, offsetBy: charCount)
        return CodeStoragePosition(lineIndex: firstLineIndex, characterIndex: charIndex)
        
//        // Fast path.
//        let utf8CodeUnitCount = firstLineChars.utf8.count
//        let charIndex = newContent.utf8.index(newContent.startIndex, offsetBy: utf8CodeUnitCount)
//        return CodeStoragePosition(lineIndex: firstLineIndex, characterIndex: charIndex)
    }
    /// This handles newlines automatically by split them into multiple lines.
    /// - Returns: Range of newrly inserted characters.
    @discardableResult
    mutating func insertCharacters(_ chs: String, at p:CodeStoragePosition) -> Range<CodeStoragePosition> {
        precondition(chs.isContiguousUTF8)
        guard !chs.isEmpty else { return p..<p }
        // Insert characters.
        let lineChars = chs.split(separator: "\n", maxSplits: .max, omittingEmptySubsequences: false)
        assert(lineChars.count != 0)
        switch lineChars.count {
        case 1:
            // Insert into existing line.
            let chs = lineChars.first!
            var line = lines[p.lineIndex]
            line.insert(contentsOf: chs, at: p.characterIndex)
            lines[p.lineIndex] = line
            let chidx = line.content.utf8.index(p.characterIndex, offsetBy: chs.utf8.count)
            return p..<CodeStoragePosition(lineIndex: p.lineIndex, characterIndex: chidx)
        default:
            // Pop target line.
            let line = lines.remove(at: p.lineIndex)
            // Split it into two parts.
            var firstLine = CodeLine(line[..<p.characterIndex])
            var lastLine = CodeLine(line[p.characterIndex...])
            
            // Prepare for offset-based operation.
            let offsetRange = 0..<lineChars.count
            // Insert line.
            var insertingLines = [CodeLine]()
            insertingLines.reserveCapacity(offsetRange.count)
            let firstOffset = offsetRange.first!
            firstLine.append(contentsOf: lineChars[firstOffset])
            insertingLines.append(firstLine)
            // Insert new middle lines.
            for offset in offsetRange.dropFirst().dropLast() {
                let line = CodeLine(lineChars[offset])
                insertingLines.append(line)
            }
            // Insert last line.
            let lastOffset = offsetRange.last!
            let lastChars = lineChars[lastOffset]
            lastLine.insert(contentsOf: lineChars[lastOffset], at: lastLine.startIndex)
            insertingLines.append(lastLine)
            lines.insert(contentsOf: insertingLines, at: p.lineIndex + offsetRange.lowerBound)
            
            let chidx = lastLine.content.utf8.index(lastLine.content.startIndex, offsetBy: lastChars.utf8.count)
            return p..<CodeStoragePosition(lineIndex: p.lineIndex + lastOffset, characterIndex: chidx)
        }
    }
}

// MARK: Temporary. I think I need re-design in SBTL...
extension Int: SBTLValueProtocol {
    public var sum: Int { self }
}

//// MARK: Conversion to Legacy
//extension CodeStorage {
//    func makeCV5String() -> CV5String {
//        /// A wrapper of text data source that acts as an `NSString`.
//        ///
//        /// This exists to support `NSTextInputClient` that requires
//        /// access to underlying `NSString`.
//        ///
//        /// Underlying text data source fully UTF-8 based with
//        /// cached UTF-16 indices at some points.
//        ///
//        @objc
//        final class IMPL: NSObject, CV5StringImpl {
//            let storage: CodeStorage
//            init(_ s: CodeStorage) {
//                storage = s
//                super.init()
//            }
//            @objc var length: UInt { UInt(storage.utf16CodeUnitCount) }
//            @objc func character(at index: UInt) -> unichar { storage.utf16CodeUnit(at: Int(index)) }
//        }
//        let impl = IMPL(self)
//        return CV5String(impl: impl)
//    }
//}
