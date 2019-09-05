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
    private var lineCharacterCounts = SBTL<Int>()
    private var lineUTF8Characters = List<String>()
    private var lineUTF16CodeUnitCounts = SBTL<Int>()
    
    public var characterCount: Int { lineCharacterCounts.sum }
    public var utf16CodeUnitCount: Int { lineUTF16CodeUnitCounts.sum }
    public func utf16CodeUnit(at i:Int) -> UTF16.CodeUnit {
        let (i,x) = lineUTF16CodeUnitCounts.indexAndOffset(for: i)
        let utf8s = lineUTF8Characters[i]
        let utf16s = utf8s.utf16
        let z = utf16s.index(utf16s.startIndex, offsetBy: x)
        let ch = utf16s[z]
        return ch
    }
    
    public var lines: Lines {
        get { Lines(of: self) }
        set(x) { self = x.core }
    }
    public struct Lines: RandomAccessCollection, MutableCollection, RangeReplaceableCollection {
        fileprivate private(set) var core: CodeStorage
        public init() { core = CodeStorage() }
        public init(of c: CodeStorage) { core = c }
        public var startIndex: Int { 0 }
        public var endIndex: Int { core.lineCharacterCounts.count }
        public subscript(_ i:Int) -> CodeLine {
            get {
                return CodeLine(
                    utf8Characters: core.lineUTF8Characters[i],
                    precomputedCharacterCount: core.lineCharacterCounts[i],
                    precomputedUTF16CodeUnitCount: core.lineUTF16CodeUnitCounts[i])
            }
            set(x) {
                core.lineUTF8Characters[i] = x.content
                core.lineCharacterCounts[i] = x.precomputedCharacterCount
                core.lineUTF16CodeUnitCounts[i] = x.precomputedUTF16CodeUnitCount
            }
        }
        public mutating func replaceSubrange<C, R>(_ subrange: R, with newElements: C) where C : Collection, R : RangeExpression, Element == C.Element, Index == R.Bound {
            core.lineUTF8Characters.replaceSubrange(subrange, with: newElements.lazy.map({ $0.content }))
            core.lineCharacterCounts.replaceSubrange(subrange, with: newElements.lazy.map({ $0.precomputedCharacterCount }))
            core.lineUTF16CodeUnitCounts.replaceSubrange(subrange, with: newElements.lazy.map({ $0.precomputedUTF16CodeUnitCount }))
        }
    }
}

// MARK: Editing
extension CodeStorage {
    mutating func removeCharacters(in range: Range<CodeStoragePosition>) {
        guard !range.isEmpty else { return }
        let firstLineIndex = range.lowerBound.line
        let firstLineChars = lines[firstLineIndex][..<range.lowerBound.characterIndex]
        let lastLineIndex = range.upperBound.line
        let lastLineChars = lines[lastLineIndex][range.upperBound.characterIndex...]
        lines.removeSubrange(firstLineIndex...lastLineIndex)
        lines.insert(CodeLine(firstLineChars + lastLineChars), at: firstLineIndex)
    }
    /// This handles newlines automatically by split them into multiple lines.
    /// - Returns: Range of newrly inserted characters.
    @discardableResult
    mutating func insertCharacters(_ chs: String, at p:CodeStoragePosition) -> Range<CodeStoragePosition> {
        guard !chs.isEmpty else { return p..<p }
        // Insert characters.
        let lineChars = chs.split(separator: "\n", maxSplits: .max, omittingEmptySubsequences: false)
        assert(lineChars.count != 0)
        switch lineChars.count {
        case 1:
            // Insert into existing line.
            let chs = lineChars.first!
            var line = lines[p.line]
            line.insert(contentsOf: chs, at: p.characterIndex)
            lines[p.line] = line
            let chidx = line.content.utf8.index(p.characterIndex, offsetBy: chs.utf8.count)
            return p..<CodeStoragePosition(line: p.line, characterIndex: chidx)
        default:
            // Pop target line.
            let line = lines.remove(at: p.line)
            // Split it into two parts.
            var firstLine = CodeLine(line[..<p.characterIndex])
            var lastLine = CodeLine(line[p.characterIndex...])
            
            // Prepare for offset-based operation.
            let offsetRange = 0..<lineChars.count
            // Insert line.
            let firstOffset = offsetRange.first!
            firstLine.append(contentsOf: lineChars[firstOffset])
            lines.insert(firstLine, at: p.line + firstOffset)
            // Insert new middle lines.
            for offset in offsetRange.dropFirst().dropLast() {
                let line = CodeLine(lineChars[offset])
                lines.insert(line, at: p.line + offset)
            }
            // Insert last line.
            let lastOffset = offsetRange.last!
            let lastChars = lineChars[lastOffset]
            lastLine.insert(contentsOf: lineChars[lastOffset], at: lastLine.startIndex)
            lines.insert(lastLine, at: p.line + lastOffset)
            let chidx = lastLine.content.utf8.index(lastLine.content.startIndex, offsetBy: lastChars.utf8.count)
            return p..<CodeStoragePosition(line: p.line + lastOffset, characterIndex: chidx)
        }
    }
}

// MARK: Temporary. I think I need re-design in SBTL...
extension Int: SBTLValueProtocol {
    public var sum: Int { self }
}

// MARK: Conversion to Legacy
extension CodeStorage {
    func makeCV5String() -> CV5String {
        /// A wrapper of text data source that acts as an `NSString`.
        ///
        /// This exists to support `NSTextInputClient` that requires
        /// access to underlying `NSString`.
        ///
        /// Underlying text data source fully UTF-8 based with
        /// cached UTF-16 indices at some points.
        ///
        @objc
        final class IMPL: NSObject, CV5StringImpl {
            let storage: CodeStorage
            init(_ s: CodeStorage) {
                storage = s
                super.init()
            }
            @objc var length: UInt { UInt(storage.utf16CodeUnitCount) }
            @objc func character(at index: UInt) -> unichar { storage.utf16CodeUnit(at: Int(index)) }
        }
        let impl = IMPL(self)
        return CV5String(impl: impl)
    }
}
