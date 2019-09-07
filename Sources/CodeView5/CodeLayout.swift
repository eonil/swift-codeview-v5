//
//  CodeLayout.swift
//  
//
//  Created by Henry Hathaway on 9/6/19.
//

import Foundation
import AppKit

struct CodeLayout {
    let config: Config
    struct Config {
        /// Treats font object as a value.
        var font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        var lineNumberFont = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        
        var lineHeight: CGFloat { -font.descender + font.ascender }
        var breakpointWidth: CGFloat { lineHeight * 2 }
        var gapBetweenBreakpointAndBody = CGFloat(5)
        var bodyX: CGFloat { breakpointWidth + gapBetweenBreakpointAndBody }
    }
    let source: CodeSource
    let imeState: IMEState?
    let boundingWidth: CGFloat

    func measureContentSize(source :CodeSource, imeState: IMEState?) -> CGSize {
        return CGSize(width: 500, height: config.lineHeight * CGFloat(source.storage.lines.count))
    }
    /// Finds index to a line WITHOUT considering existence of target line.
    func potentialLineIndex(at y:CGFloat) -> Int {
        let h = config.lineHeight
        let n = (y / h).rounded(.down)
        let i = Int(exactly: n)!
        return i
    }
    /// Finds index to a line at a point.
    func clampingLineIndex(at y:CGFloat) -> Int {
        let i = potentialLineIndex(at: y)
        return i.clamping(in: source.storage.lines.indices)
    }
    /// Finds position of a character in a line at a point.
    /// - Returns: `nil` if supplied point is not belong to any character in the line.
    func clampingCharacterIndex(at x:CGFloat, inLineAt offset:Int, with f:NSFont) -> String.Index {
        let x1 = x - config.bodyX
        let hh = config.lineHeight / 2
        let line = source.storage.lines[offset]
        let ctline = CTLine.make(with: line.content, font: f)
        let f = ctline.bounds
        let xs = f.minX...f.maxX
        if xs.contains(x1) {
            let utf16Offset = CTLineGetStringIndexForPosition(ctline, CGPoint(x: x1, y: hh))
            precondition(utf16Offset != kCFNotFound)
            let i = line.content.utf16.index(line.content.utf16.startIndex, offsetBy: utf16Offset)
            return i
        }
        else {
            let s = line.content
            if x1 <= xs.lowerBound { return s.startIndex }
            if x1 >= xs.upperBound { return s.endIndex }
            fatalError("Unreachable code.")
        }
    }
    /// Finds position of a character and its line at a point.
    /// - Returns: `nil` if supplied point is not belong to any character in any line.
    func clampingPosition(at p:CGPoint) -> CodeStoragePosition {
        let lineIndex = potentialLineIndex(at: p.y)
        let storedlineIndices = source.storage.lines.indices
        if storedlineIndices.contains(lineIndex) {
            let charIndex = clampingCharacterIndex(at: p.x, inLineAt: lineIndex, with: config.font)
            return CodeStoragePosition(line: lineIndex, characterIndex: charIndex)
        }
        else {
            if lineIndex < storedlineIndices.lowerBound {
                let lineIndex = storedlineIndices.first!
                let lineContent = source.storage.lines[lineIndex].content
                let charIndex = lineContent.startIndex
                return CodeStoragePosition(line: lineIndex, characterIndex: charIndex)
            }
            if lineIndex >= storedlineIndices.upperBound {
                let lineIndex = storedlineIndices.last!
                let lineContent = source.storage.lines[lineIndex].content
                let charIndex = lineContent.endIndex
                return CodeStoragePosition(line: lineIndex, characterIndex: charIndex)
            }
            fatalError("Unreachable code.")
        }
    }
    
    func frameOfLine(at offset: Int) -> CGRect {
        let w = boundingWidth
        let h = config.lineHeight
        let y = CGFloat(offset) * h
        return CGRect(x: 0, y: y, width: w, height: h)
    }
    /// This does not consider IME state.
    func frameOfTextInLine(at offset: Int) -> CGRect {
        let s = source.storage.lines[offset].content
        let r = s.startIndex..<s.endIndex
        return frameOfTextSubrange(r, inLineAt: offset)
    }
    func frameOfLineNumberArea(at offset: Int) -> CGRect {
        let lineFrame = frameOfLine(at: offset)
        return lineFrame.divided(atDistance: config.breakpointWidth, from: .minXEdge).slice
    }
    /// This does not consider IME state.
    /// Take care that this frame considers breakpoint area and is clipped by line frame.
    /// Therefore can be different with result of `frameOfTextSubrange` for same input.
    func frameOfTextSubrange(_ r:Range<String.Index>, inLineAt offset: Int) -> CGRect {
        let lineFrame = frameOfLine(at: offset)
        let lineContent = source.storage.lines[offset].content
        let subframeInTextBounds = lineContent.frameOfCharactersInSubrange(r, withFont: config.font)
        let subtextFrame = subframeInTextBounds.offsetBy(dx: config.bodyX, dy: lineFrame.minY)
        return CGRect(
            x: subtextFrame.minX,
            y: lineFrame.minY,
            width: subtextFrame.width,
            height: lineFrame.height)
    }
    /// This does not consider IME state.
    /// - Parameter offset:
    ///     Index to a line in code-storage.
    ///     This must be a valid index. Otherwise program crashes.
    func frameOfSelectionInLine(at offset: Int) -> CGRect {
        precondition(source.storage.lines.indices.contains(offset))
        let selRange = source.selectionRange
        let selCharRange = selRange.characterRangeOfLine(at: offset, in: source.storage)
        let selFrame = frameOfTextSubrange(selCharRange, inLineAt: offset)
        return selFrame
    }
    func frameOfIMESelection() -> CGRect? {
        guard let imes = imeState else { return nil }
        let lineFrame = frameOfLine(at: source.caretPosition.line)
        let caretOrSelFrame = frameOfCaret() ?? frameOfSelectionInLine(at: source.caretPosition.line)
        let s = imes.incompleteText
        let r = imes.selectionInIncompleteText
        let x = caretOrSelFrame.maxX
        let f = s.frameOfCharactersInSubrange(r, withFont: config.font)
        return CGRect(x: x + f.minX, y: lineFrame.minY, width: f.width, height: lineFrame.height)
    }
    
    /// - Returns:
    ///     `nil` if caret cannot be displayed.
    ///     For example, if there's a selection, caret will not be rendered.
    func frameOfCaret() -> CGRect? {
        guard source.selectionRange.isEmpty && (imeState?.selectionInIncompleteText.isEmpty ?? true) else { return nil }
        let p = source.caretPosition
        let line = source.storage.lines[p.line]
        let x = CTLine.make(with: String(line[..<p.characterIndex]), font: config.font).bounds.width
        let y = config.lineHeight * CGFloat(p.line)
        let sIME = imeState?.incompleteText ?? ""
        let pIME = imeState?.selectionInIncompleteText.lowerBound ?? .zero
        let xIME = CTLine.make(with: String(sIME[..<pIME]), font: config.font).bounds.width
        let caretFrame = CGRect(
            x: config.bodyX + x + xIME,
            y: y,
            width: 1,
            height: config.lineHeight)
        return caretFrame
    }
    func frameOfBreakpointInLine(at offset: Int) -> CGRect {
        let w = config.breakpointWidth
        let h = config.lineHeight
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

