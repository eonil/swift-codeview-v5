//
//  IMPLStringCore.swift
//  CodeView5Demo
//
//  Created by Henry Hathaway on 9/2/19.
//  Copyright © 2019 Eonil. All rights reserved.
//

import Foundation
import SBTL
import CodeView5CustomNSString

/// Stores lines and characters.
/// This is simple passive dumb storage.
/// There's no concept of versioning or history or timeline.
public struct CodeTextStorage {
//    /// Unique keys for each lines.
//    /// This is unique only in current storage scope.
//    private var lineKeyList = List<CodeLineKey>()
//    /// Line unique key manager.
//    private var lineKeyManagement = CodeLineKeyManagement()
    
    private var implLines = BTList<CodeLine>()
    
    public init() {}
//    /// All keys in this storage for each lines at same indices.
//    public var keys: Keys {
//        get { Keys(of: self) }
//        set(x) { self = x.core }
//    }
//    public struct Keys: RandomAccessCollection {
//        fileprivate private(set) var core: CodeTextStorage
//        public init() { core = CodeTextStorage() }
//        public init(of c: CodeTextStorage) { core = c }
//        public var startIndex: Int { 0 }
//        public var endIndex: Int { core.lineCharacterCountList.count }
//        public subscript(_ i:Int) -> CodeLineKey { core.lineKeyList[i] }
//    }
    /// All lines in this storage.
    public var lines: Lines {
        get { Lines(of: self) }
        set(x) { self = x.core }
    }
    /// Guarantees that offsets and indices are always same.
    /// Anyway, I recommend you to use `atOffset`/`set(_,atOffset)` methods
    /// to be clear.
    public struct Lines: RandomAccessCollection, MutableCollection, RangeReplaceableCollection {
        fileprivate private(set) var core: CodeTextStorage
        public init() { core = CodeTextStorage() }
        public init(of c: CodeTextStorage) { core = c }
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
extension CodeTextStorage {
    public typealias LineCharacterRange = (lineOffset: Int, characterUTF8OffsetRange: Range<Int>)
    public func characterRangesOfLines(in range: Range<CodeStoragePosition>) -> [LineCharacterRange] {
        switch range.includedLineOffsetRange.count {
        case 0:
            let p = range.lowerBound
            let x = p.characterUTF8Offset
            return [(p.lineOffset, x..<x)]
        case 1:
            let lineOffset = range.lowerBound.lineOffset
            let charUTF8OffsetRange = range.characterUTF8OffsetRangeOfLine(at: lineOffset, in: self)
            return [(lineOffset, charUTF8OffsetRange)]
        default:
            var rs = [LineCharacterRange]()
            for lineOffset in range.includedLineOffsetRange {
                let charUTF8OffsetRange = range.characterUTF8OffsetRangeOfLine(at: lineOffset, in: self)
                rs.append((lineOffset, charUTF8OffsetRange))
            }
            return rs
        }
    }
    /// You can get single string by calling `join(separator: "\n")` on returning array.
    public func lineContents(in range: Range<CodeStoragePosition>) -> [Substring] {
        let lineCharRanges = characterRangesOfLines(in: range)
        return lineCharRanges.map({ lines.atOffset($0.lineOffset).characters.subcontentInUTF8OffsetRange($0.characterUTF8OffsetRange) })
//        switch range.includedLineOffsetRange.count {
//        case 0:
//            return [Substring()]
//        case 1:
//            let lineOffset = range.lowerBound.lineOffset
//            let charUTF8OffsetRange = range.characterUTF8OffsetRangeOfLine(at: lineOffset, in: self)
//            let ss = lines.atOffset(lineOffset).content.subcontentInUTF8OffsetRange(charUTF8OffsetRange)
//            return [ss]
//        default:
//            var sss = [Substring]()
//            for lineOffset in range.includedLineOffsetRange {
//                let charUTF8OffsetRange = range.characterUTF8OffsetRangeOfLine(at: lineOffset, in: self)
//                let charContent = lines.atOffset(lineOffset).content.subcontentInUTF8OffsetRange(charUTF8OffsetRange)
//                sss.append(charContent)
//            }
//            return sss
//        }
    }
    /// - Returns:
    ///     Position where the characters removed.
    ///     Beware that character index is based on current line's content.
    mutating func removeCharacters(in range: Range<CodeStoragePosition>) -> CodeStoragePosition {
        guard !range.isEmpty else { return range.upperBound }
        let firstLineOffset = range.lowerBound.lineOffset
        let firstLineIndex = lines.startIndex + firstLineOffset
        let firstLineCharUTF8OffsetRange = 0..<range.lowerBound.characterUTF8Offset
        let firstLineChars = lines.atOffset(firstLineOffset).characters.subcontentInUTF8OffsetRange(firstLineCharUTF8OffsetRange)
        let lastLineOffset = range.upperBound.lineOffset
        let lastLineIndex = lines.startIndex + lastLineOffset
        let lastLineCharUTF8OffsetRange = range.upperBound.characterUTF8Offset...
        let lastLineChars = lines.atOffset(lastLineOffset).characters.subcontentInUTF8OffsetRange(lastLineCharUTF8OffsetRange)
        lines.removeSubrange(firstLineIndex...lastLineIndex)
        var newContent = firstLineChars
        newContent.append(contentsOf: lastLineChars)
        lines.insert(CodeLine(newContent), at: firstLineIndex)
        return CodeStoragePosition(lineOffset: firstLineOffset, characterUTF8Offset: firstLineChars.utf8.count)
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
            let lineIndex = lines.startIndex + p.lineOffset
            var line = lines.atOffset(p.lineOffset)
//            let charIndex = line.characters.indexFromUTF8Offset(p.characterUTF8Offset)
            line.insert(contentsOf: chs, at: p.characterUTF8Offset)
            lines.set(line, atOffset: lineIndex)
            return p..<CodeStoragePosition(
                lineOffset: p.lineOffset,
                characterUTF8Offset: p.characterUTF8Offset + chs.utf8.count)
        default:
            // Pop target line.
            let lineIndex = lines.startIndex + p.lineOffset
            let line = lines.remove(at: lineIndex)
            // Split it into two parts.
            var firstLine = CodeLine(line.characters.subcontentInUTF8OffsetRange(..<p.characterUTF8Offset))
            var lastLine = CodeLine(line.characters.subcontentInUTF8OffsetRange(p.characterUTF8Offset...))
            
            // Prepare for offset-based operation.
            let lineOffsetRange = 0..<lineChars.count
            // Insert line.
            var insertingLines = [CodeLine]()
            insertingLines.reserveCapacity(lineOffsetRange.count)
            let firstLineOffset = lineOffsetRange.first!
            firstLine.append(contentsOf: lineChars[firstLineOffset])
            insertingLines.append(firstLine)
            // Insert new middle lines.
            for offset in lineOffsetRange.dropFirst().dropLast() {
                let line = CodeLine(lineChars[offset])
                insertingLines.append(line)
            }
            // Insert last line.
            let lastLineOffset = lineOffsetRange.last!
            let lastLineChars = lineChars[lastLineOffset]
            lastLine.insert(contentsOf: lineChars[lastLineOffset], at: lastLine.startIndex)
            insertingLines.append(lastLine)
            lines.insert(contentsOf: insertingLines, at: lineIndex + lineOffsetRange.lowerBound)
            
            return p..<CodeStoragePosition(
                lineOffset: lineIndex + lastLineOffset,
                characterUTF8Offset: lastLineChars.utf8.count)
        }
    }
}

//// MARK: Temporary. I think I need re-design in SBTL...
//extension Int: SBTLValueProtocol {
//    public var sum: Int { self }
//}

//// MARK: Conversion to Legacy
//extension CodeTextStorage {
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
