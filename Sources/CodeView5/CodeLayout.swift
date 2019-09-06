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
        
        var lineHeight: CGFloat { -font.descender + font.ascender }
        var breakpointWidth: CGFloat { lineHeight * 2 }
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
        let x1 = x - config.breakpointWidth
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
    func frameOfLineNumber(at offset: Int) -> CGRect {
        let lineFrame = frameOfLine(at: offset)
        return lineFrame.divided(atDistance: config.breakpointWidth, from: .minXEdge).slice
    }
    /// This does not consider IME state.
    func frameOfTextSubrange(_ r:Range<String.Index>, inLineAt offset: Int) -> CGRect {
        let lineFrame = frameOfLine(at: offset)
        let s = source.storage.lines[offset].content
        let s1 = s[..<r.lowerBound]
        let s2 = s[r.lowerBound..<r.upperBound]
        let ctline1 = CTLine.make(with: String(s1), font: config.font)
        let ctline2 = CTLine.make(with: String(s2), font: config.font)
        let bounds1 = CTLineGetBoundsWithOptions(ctline1, [])
        let bounds2 = CTLineGetBoundsWithOptions(ctline2, [])
        let f = CGRect(
            x: config.breakpointWidth + bounds1.maxX,
            y: lineFrame.minY,
            width: bounds2.width,
            height: lineFrame.height)
        return f
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
            x: config.breakpointWidth + x + xIME,
            y: y,
            width: 1,
            height: config.lineHeight)
        return caretFrame
    }
    func frameOfBreakpointInLine(at offset: Int) -> CGRect {
        let w = config.breakpointWidth - 5
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

