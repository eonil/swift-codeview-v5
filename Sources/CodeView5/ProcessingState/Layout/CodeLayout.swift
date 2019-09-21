//
//  CodeLayout.swift
//  
//
//  Created by Henry Hathaway on 9/6/19.
//

import Foundation
import AppKit

public struct CodeLayout {
    let config: CodeConfig
    let source: CodeSource
    let imeState: IMEState?
    let boundingWidth: CGFloat

    func measureContentSize(source :CodeSource, imeState: IMEState?) -> CGSize {
        return CGSize(width: 500, height: config.rendering.lineHeight * CGFloat(source.storage.lines.count))
    }
    /// Finds index to a line WITHOUT considering existence of target line.
    func potentialLineOffset(at y:CGFloat) -> Int {
        let h = config.rendering.lineHeight
        let n = (y / h).rounded(.down)
        let i = Int(exactly: n)!
        return i
    }
    /// Finds offset to a line at a point.
    func clampingLineOffset(at y:CGFloat) -> Int {
        let lineOffset = potentialLineOffset(at: y)
        return lineOffset.clamping(in: source.storage.lines.offsets)
    }
    /// Finds offset of a character in a line at a point.
    /// - Returns: `nil` if supplied point is not belong to any character in the line.
    func clampingCharacterUTF8Offset(at x:CGFloat, inLineAt lineOffset:Int, with f:NSFont) -> Int {
        let x1 = x - config.rendering.bodyX
        let hh = config.rendering.lineHeight / 2
        let line = source.storage.lines.atOffset(lineOffset)
        let ctline = CTLine.make(with: line.content, font: f)
        let f = ctline.bounds
        let xs = f.minX...f.maxX
        if xs.contains(x1) {
            let utf16Offset = CTLineGetStringIndexForPosition(ctline, CGPoint(x: x1, y: hh))
            precondition(utf16Offset != kCFNotFound)
            let charIndex = line.content.utf16.index(line.content.utf16.startIndex, offsetBy: utf16Offset)
            let charUTF8Offset = line.content.utf8OffsetFromIndex(charIndex)
            return charUTF8Offset
        }
        else {
            let s = line.content
            if x1 <= xs.lowerBound { return 0 }
            if x1 >= xs.upperBound { return s.utf8.count }
            fatalError("Unreachable code.")
        }
    }
    
    /// Finds position of a character and its line at a point.
    /// - Returns: `nil` if supplied point is not belong to any character in any line.
    func clampingPosition(at p:CGPoint) -> CodeStoragePosition {
        let lineOffset = potentialLineOffset(at: p.y)
        let storedLineOffsets = source.storage.lines.offsets
        if storedLineOffsets.contains(lineOffset) {
            let charUTF8Offset = clampingCharacterUTF8Offset(at: p.x, inLineAt: lineOffset, with: config.rendering.font)
            return CodeStoragePosition(lineOffset: lineOffset, characterUTF8Offset: charUTF8Offset)
        }
        else {
            if lineOffset < storedLineOffsets.lowerBound {
                return source.startPosition
            }
            if lineOffset >= storedLineOffsets.upperBound {
                return source.endPosition
            }
            fatalError("Unreachable code.")
        }
    }
    
    public func frameOfLine(at lineOffset: Int) -> CGRect {
        let w = boundingWidth
        let h = config.rendering.lineHeight
        let y = CGFloat(lineOffset) * h
        return CGRect(x: 0, y: y, width: w, height: h)
    }
    /// This does not consider IME state.
    public func frameOfTextInLine(at lineOffset: Int) -> CGRect {
        let s = source.storage.lines.atOffset(lineOffset).content
        let r = 0..<s.utf8.count
        return frameOfTextUTF8OffsetSubrange(r, inLineAt: lineOffset)
    }
    func frameOfLineNumberArea(at offset: Int) -> CGRect {
        let lineFrame = frameOfLine(at: offset)
        return lineFrame.divided(atDistance: config.rendering.lineNumberAreaWidth, from: .minXEdge).slice
    }
    /// This does not consider IME state.
    /// Take care that this frame considers breakpoint area and is clipped by line frame.
    /// Therefore can be different with result of `frameOfTextSubrange` for same input.
    public func frameOfTextUTF8OffsetSubrange(_ charUTF8OffsetRange:Range<Int>, inLineAt lineOffset: Int) -> CGRect {
        let lineFrame = frameOfLine(at: lineOffset)
        let lineContent = source.storage.lines.atOffset(lineOffset).content
        let subframeInTextBounds = lineContent.frameOfCharactersInUTF8OffsetSubrange(charUTF8OffsetRange, withFont: config.rendering.font)
        let subtextFrame = subframeInTextBounds.offsetBy(dx: config.rendering.bodyX, dy: lineFrame.minY)
        return CGRect(
            x: subtextFrame.minX,
            y: lineFrame.minY,
            width: subtextFrame.width,
            height: lineFrame.height)
    }
    public func frameOfTextUTF8OffsetSubrange(_ charUTF8OffsetRange:PartialRangeFrom<Int>, inLineAt lineOffset: Int) -> CGRect {
        let lineContent = source.storage.lines.atOffset(lineOffset).content
        return frameOfTextUTF8OffsetSubrange(charUTF8OffsetRange.lowerBound..<lineContent.utf8.count, inLineAt: lineOffset)
    }
    public func frameOfTextUTF8OffsetSubrange(_ charUTF8OffsetRange:PartialRangeUpTo<Int>, inLineAt lineOffset: Int) -> CGRect {
        return frameOfTextUTF8OffsetSubrange(0..<charUTF8OffsetRange.upperBound, inLineAt: lineOffset)
    }
    /// This does not consider IME state.
    /// - Parameter offset:
    ///     Index to a line in code-storage.
    ///     This must be a valid index. Otherwise program crashes.
    func frameOfSelectionInLine(at lineOffset: Int) -> CGRect {
        precondition(source.storage.lines.offsets.contains(lineOffset))
        let selRange = source.selectionRange
        let selCharUTF8OffsetRange = selRange.characterUTF8OffsetRangeOfLine(at: lineOffset, in: source.storage)
        let selFrame = frameOfTextUTF8OffsetSubrange(selCharUTF8OffsetRange, inLineAt: lineOffset)
        return selFrame
    }
    func frameOfIMESelection() -> CGRect? {
        guard let imes = imeState else { return nil }
        let lineFrame = frameOfLine(at: source.caretPosition.lineOffset)
        let caretOrSelFrame = frameOfCaret() ?? frameOfSelectionInLine(at: source.caretPosition.lineOffset)
        let s = imes.incompleteText
        let r = imes.selectionInIncompleteTextAsUTF8CodeUnitOffset
        let x = caretOrSelFrame.maxX
        let f = s.frameOfCharactersInUTF8OffsetSubrange(r, withFont: config.rendering.font)
        return CGRect(x: x + f.minX, y: lineFrame.minY, width: f.width, height: lineFrame.height)
    }
    
    /// - Returns:
    ///     `nil` if caret cannot be displayed.
    ///     For example, if there's a selection, caret will not be rendered.
    public func frameOfCaret() -> CGRect? {
        guard source.selectionRange.isEmpty && (imeState?.selectionInIncompleteText.isEmpty ?? true) else { return nil }
        let p = source.caretPosition
        let line = source.storage.lines.atOffset(p.lineOffset)
        let chars = line.content.subcontentInUTF8OffsetRange(..<p.characterUTF8Offset)
        let x = CTLine.make(with: chars, font: config.rendering.font).bounds.width
        let y = config.rendering.lineHeight * CGFloat(p.lineOffset)
        let sIME = imeState?.incompleteText ?? ""
        let pIME = imeState?.selectionInIncompleteText.lowerBound ?? "".startIndex
        let xIME = CTLine.make(with: sIME[..<pIME], font: config.rendering.font).bounds.width
        let caretFrame = CGRect(
            x: config.rendering.bodyX + x + xIME,
            y: y,
            width: 1,
            height: config.rendering.lineHeight)
        return caretFrame
    }
    func frameOfBreakpointInLine(at offset: Int) -> CGRect {
        let w = config.rendering.breakpointWidth
        let h = config.rendering.lineHeight
        let y = h * CGFloat(offset)
        return CGRect(x: 0, y: y, width: w, height: h)
    }
}

private extension Comparable {
    func clamping(in r:Range<Self>) -> Self {
        if self < r.lowerBound { return r.lowerBound }
        if self > r.upperBound { return r.upperBound }
        return self
    }
}
