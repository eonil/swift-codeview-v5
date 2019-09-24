////
////  File.swift
////  
////
////  Created by Henry Hathaway on 9/24/19.
////
//
//import Foundation
//
///// Stores styles for each characters.
///// This is separated to get updated and rendered independently.
/////
//public struct CodeStyleStorage {
//    /// All lines in this storage.
//    public var lines = BTList<CodeStyleLine>()
//    public init() {}
//}
//
//// MARK: Editing
//extension CodeStyleStorage {
//    /// You can get single string by calling `join(separator: "\n")` on returning array.
//    public func lineContents(in range: Range<CodeStoragePosition>) -> [ArraySlice<CodeStyle>] {
//        guard !range.isEmpty else { return [Substring()] }
//        switch range.includedLineOffsetRange.count {
//        case 0:
//            return [Substring()]
//        case 1:
//            let lineOffset = range.lowerBound.lineOffset
//            let lineIndex = lines.startIndex + lineOffset
//            let charUTF8OffsetRange = range.characterUTF8OffsetRangeOfLine(at: lineOffset, in: self)
//            let ss = lines[lineIndex].content.subcontentInUTF8OffsetRange(charUTF8OffsetRange)
//            return [ss]
//        default:
//            var sss = [Substring]()
//            for lineOffset in range.includedLineOffsetRange {
//                let lineIndex = lines.startIndex + lineOffset
//                let charUTF8OffsetRange = range.characterUTF8OffsetRangeOfLine(at: lineOffset, in: self)
//                let charContent = lines[lineIndex].content.subcontentInUTF8OffsetRange(charUTF8OffsetRange)
//                sss.append(charContent)
//            }
//            return sss
//        }
//    }
//    /// - Returns:
//    ///     Position where the characters removed.
//    ///     Beware that character index is based on current line's content.
//    mutating func removeCharacters(in range: Range<CodeStoragePosition>) -> CodeStoragePosition {
//        guard !range.isEmpty else { return range.upperBound }
//        let firstLineOffset = range.lowerBound.lineOffset
//        let firstLineIndex = lines.startIndex + firstLineOffset
//        let firstLineCharUTF8OffsetRange = 0..<range.lowerBound.characterUTF8Offset
//        let firstLineChars = lines[firstLineOffset].content.subcontentInUTF8OffsetRange(firstLineCharUTF8OffsetRange)
//        let lastLineOffset = range.upperBound.lineOffset
//        let lastLineIndex = lines.startIndex + lastLineOffset
//        let lastLineCharUTF8OffsetRange = range.upperBound.characterUTF8Offset...
//        let lastLineChars = lines[lastLineIndex].content.subcontentInUTF8OffsetRange(lastLineCharUTF8OffsetRange)
//        lines.removeSubrange(firstLineIndex...lastLineIndex)
//        var newContent = firstLineChars
//        newContent.append(contentsOf: lastLineChars)
//        lines.insert(CodeLine(newContent), at: firstLineIndex)
//        return CodeStoragePosition(lineOffset: firstLineOffset, characterUTF8Offset: firstLineChars.utf8.count)
//    }
//    /// This handles newlines automatically by split them into multiple lines.
//    /// - Returns: Range of newrly inserted characters.
//    @discardableResult
//    mutating func insertCharacters(_ chs: String, at p:CodeStoragePosition) -> Range<CodeStoragePosition> {
//        precondition(chs.isContiguousUTF8)
//        guard !chs.isEmpty else { return p..<p }
//        // Insert characters.
//        let lineChars = chs.split(separator: "\n", maxSplits: .max, omittingEmptySubsequences: false)
//        assert(lineChars.count != 0)
//        switch lineChars.count {
//        case 1:
//            // Insert into existing line.
//            let chs = lineChars.first!
//            let lineIndex = lines.startIndex + p.lineOffset
//            var line = lines[lineIndex]
//            let charIndex = line.content.indexFromUTF8Offset(p.characterUTF8Offset)
//            line.insert(contentsOf: chs, at: charIndex)
//            lines[lineIndex] = line
//            return p..<CodeStoragePosition(
//                lineOffset: p.lineOffset,
//                characterUTF8Offset: p.characterUTF8Offset + chs.utf8.count)
//        default:
//            // Pop target line.
//            let lineIndex = lines.startIndex + p.lineOffset
//            let line = lines.remove(at: lineIndex)
//            // Split it into two parts.
//            var firstLine = CodeStyleLine(line.content.subcontentInUTF8OffsetRange(..<p.characterUTF8Offset))
//            var lastLine = CodeStyleLine(line.content.subcontentInUTF8OffsetRange(p.characterUTF8Offset...))
//            
//            // Prepare for offset-based operation.
//            let lineOffsetRange = 0..<lineChars.count
//            // Insert line.
//            var insertingLines = [CodeLine]()
//            insertingLines.reserveCapacity(lineOffsetRange.count)
//            let firstLineOffset = lineOffsetRange.first!
//            firstLine.append(contentsOf: lineChars[firstLineOffset])
//            insertingLines.append(firstLine)
//            // Insert new middle lines.
//            for offset in lineOffsetRange.dropFirst().dropLast() {
//                let line = CodeLine(lineChars[offset])
//                insertingLines.append(line)
//            }
//            // Insert last line.
//            let lastLineOffset = lineOffsetRange.last!
//            let lastLineChars = lineChars[lastLineOffset]
//            lastLine.insert(contentsOf: lineChars[lastLineOffset], at: lastLine.startIndex)
//            insertingLines.append(lastLine)
//            lines.insert(contentsOf: insertingLines, at: lineIndex + lineOffsetRange.lowerBound)
//            
//            return p..<CodeStoragePosition(
//                lineOffset: lineIndex + lastLineOffset,
//                characterUTF8Offset: lastLineChars.utf8.count)
//        }
//    }
//}
//
//public struct CodeStyleLine {
//    var content = ArraySlice<CodeStyle>()
//}
//
//
//
//
//
//
////struct CodeStyleStorage {
////    var lines = [CodeStyleLine]()
////}
////
/////// This can be treated in two ways.
/////// - A collection of spans.
/////// - A collection of styles for each "virtual" characters.
/////// This type works as second concept, therefore to provide
/////// easier sync with source text. But you are free to control
/////// span level stuffs if you want.
/////// All indices are UTF-8 code unit offsets.
///////
////struct CodeStyleLine: RandomAccessCollection {
////    /// You are supposed to have small number of spans.
////    /// Like less than 50 items at maximum.
////    private var spanUTF8CountSum = 0
////    var spans = [CodeStyleSpan]() {
////        didSet {
////            spanUTF8CountSum = spans.lazy.map({ $0.utf8Count }).reduce(0, +)
////        }
////    }
////    var startIndex: Int { 0 }
////    var endIndex: Int { spanUTF8CountSum }
////    subscript(_ i:Int) -> CodeStyle {
////
////    }
////}
////
////struct CodeStyleSpan {
////    var utf8Count = 0
////    var style = CodeStyle.plain
////}
