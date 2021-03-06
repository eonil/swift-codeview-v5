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
    let storage: CodeStorage
    let imeState: IMEState?
    let boundingWidth: CGFloat

    func measureContentSize(storage :CodeStorage, imeState: IMEState?) -> CGSize {
        return CGSize(width: 500, height: config.rendering.gridFittingLineHeight * CGFloat(storage.text.lines.count))
    }
    /// Finds index to a line WITHOUT considering existence of target line.
    func potentialLineOffset(at y:CGFloat) -> Int {
        let h = config.rendering.gridFittingLineHeight
        let n = (y / h).rounded(.down)
        let i = Int(exactly: n)!
        return i
    }
    /// Finds offset to a line at a point.
    func clampingLineOffset(at y:CGFloat) -> Int {
        let lineOffset = potentialLineOffset(at: y)
        return lineOffset.clamping(in: storage.text.lines.offsets)
    }
    /// Finds offset of a character in a line at a point.
    /// - Returns: `nil` if supplied point is not belong to any character in the line.
    func clampingCharacterUTF8Offset(at x:CGFloat, inLineAt lineOffset:Int, with f:NSFont) -> Int {
        let x1 = x - config.rendering.bodyX
        let hh = config.rendering.gridFittingLineHeight / 2
        let line = storage.text.lines.atOffset(lineOffset)
        let ctline = CTLine.make(with: line.characters, font: f)
        let f = ctline.__bounds
        let xs = f.minX...f.maxX
        if xs.contains(x1) {
            let utf16Offset = CTLineGetStringIndexForPosition(ctline, CGPoint(x: x1, y: hh))
            precondition(utf16Offset != kCFNotFound)
            let charIndex = line.characters.utf16.index(line.characters.utf16.startIndex, offsetBy: utf16Offset)
            let charUTF8Offset = line.characters.utf8OffsetFromIndex(charIndex)
            return charUTF8Offset
        }
        else {
            let s = line.characters
            if x1 <= xs.lowerBound { return 0 }
            if x1 >= xs.upperBound { return s.utf8.count }
            fatalError("Unreachable code.")
        }
    }
    
    /// Finds position of a character and its line at a point.
    /// - Returns: `nil` if supplied point is not belong to any character in any line.
    func clampingPosition(at p:CGPoint) -> CodeStoragePosition {
        let lineOffset = potentialLineOffset(at: p.y)
        let storedLineOffsets = storage.text.lines.offsets
        if storedLineOffsets.contains(lineOffset) {
            let charUTF8Offset = clampingCharacterUTF8Offset(at: p.x, inLineAt: lineOffset, with: config.rendering.standardFont)
            return CodeStoragePosition(lineOffset: lineOffset, characterUTF8Offset: charUTF8Offset)
        }
        else {
            if lineOffset < storedLineOffsets.lowerBound {
                return storage.startPosition
            }
            if lineOffset >= storedLineOffsets.upperBound {
                return storage.endPosition
            }
            fatalError("Unreachable code.")
        }
    }
    
    public func frameOfLine(at lineOffset: Int) -> CGRect {
        let w = boundingWidth
        let h = config.rendering.gridFittingLineHeight
        let y = CGFloat(lineOffset) * h
        return CGRect(x: 0, y: y, width: w, height: h)
    }
//    /// This does not consider IME state.
//    public func frameOfTextInLine(at lineOffset: Int) -> CGRect {
//        let s = storage.text.lines.atOffset(lineOffset).characters
//        let r = 0..<s.utf8.count
//        return frameOfTextUTF8OffsetSubrange(r, inLineAt: lineOffset)
//    }
    func frameOfLineNumberArea(at lineOffset: Int) -> CGRect {
        let lineFrame = frameOfLine(at: lineOffset)
        return lineFrame.divided(atDistance: config.rendering.lineNumberAreaWidth, from: .minXEdge).slice
    }
    public func frameOfLineTextArea(at lineOffset: Int) -> CGRect {
        let lineFrame = frameOfLine(at: lineOffset)
        return lineFrame.divided(atDistance: config.rendering.bodyX, from: .minXEdge).remainder
    }
    /// This does not consider IME state.
    /// Take care that this frame considers breakpoint area and is clipped by line frame.
    /// Therefore can be different with result of `frameOfTextSubrange` for same input.
    public func frameOfTextUTF8OffsetSubrange(_ charUTF8OffsetRange:Range<Int>, inLineAt lineOffset: Int) -> CGRect {
        let lineFrame = frameOfLine(at: lineOffset)
        let lineContent = storage.text.lines.atOffset(lineOffset).characters
        let subframeInTextBounds = lineContent.frameOfCharactersInUTF8OffsetSubrange(charUTF8OffsetRange, withFont: config.rendering.standardFont)
        let subtextFrame = subframeInTextBounds.offsetBy(dx: config.rendering.bodyX, dy: lineFrame.minY)
        return CGRect(
            x: subtextFrame.minX,
            y: lineFrame.minY,
            width: subtextFrame.width,
            height: lineFrame.height)
    }
    public func frameOfTextUTF8OffsetSubrange(_ charUTF8OffsetRange:PartialRangeFrom<Int>, inLineAt lineOffset: Int) -> CGRect {
        let lineContent = storage.text.lines.atOffset(lineOffset).characters
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
        precondition(storage.text.lines.offsets.contains(lineOffset))
        let selRange = storage.selectionRange
        let selCharUTF8OffsetRange = selRange.characterUTF8OffsetRangeOfLine(at: lineOffset, in: storage.text)
        let selFrame = frameOfTextUTF8OffsetSubrange(selCharUTF8OffsetRange, inLineAt: lineOffset)
        return selFrame
    }
    func frameOfIMESelection() -> CGRect? {
        guard let imes = imeState else { return nil }
        let lineFrame = frameOfLine(at: storage.caretPosition.lineOffset)
        let caretOrSelFrame = frameOfCaret() ?? frameOfSelectionInLine(at: storage.caretPosition.lineOffset)
        let s = imes.incompleteText
        let r = imes.selectionInIncompleteTextAsUTF8CodeUnitOffset
        let x = caretOrSelFrame.maxX
        let f = s.frameOfCharactersInUTF8OffsetSubrange(r, withFont: config.rendering.standardFont)
        return CGRect(x: x + f.minX, y: lineFrame.minY, width: f.width, height: lineFrame.height)
    }
    
    /// - Returns:
    ///     `nil` if caret cannot be displayed.
    ///     For example, if there's a selection, caret will not be rendered.
    public func frameOfCaret() -> CGRect? {
        guard storage.selectionRange.isEmpty && (imeState?.selectionInIncompleteText.isEmpty ?? true) else { return nil }
        let p = storage.caretPosition
        let line = storage.text.lines.atOffset(p.lineOffset)
        let chars = line.characters.subcontentInUTF8OffsetRange(..<p.characterUTF8Offset)
        let x = CTLine.make(with: chars, font: config.rendering.standardFont).__bounds.width
        let y = config.rendering.gridFittingLineHeight * CGFloat(p.lineOffset)
        let sIME = imeState?.incompleteText ?? ""
        let pIME = imeState?.selectionInIncompleteText.lowerBound ?? "".startIndex
        let xIME = CTLine.make(with: sIME[..<pIME], font: config.rendering.standardFont).__bounds.width
        let caretFrame = CGRect(
            x: config.rendering.bodyX + x + xIME,
            y: y,
            width: 1,
            height: config.rendering.gridFittingLineHeight)
        return caretFrame
    }
    func frameOfBreakpointInLine(at offset: Int) -> CGRect {
        let w = config.rendering.breakpointWidth
        let h = config.rendering.gridFittingLineHeight
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
