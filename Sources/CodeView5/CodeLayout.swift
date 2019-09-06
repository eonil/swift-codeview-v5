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
    
    /// Finds offset of a line at a point.
    /// - Returns: `nil` if supplied point is not belong to any line.
    func lineIndex(at y:CGFloat) -> Int? {
        let h = config.lineHeight
        let n = (y / h).rounded(.down)
        guard let i = Int(exactly: n) else { return nil }
        guard source.storage.lines.indices.contains(i) else { return nil }
        return i
    }
    /// Finds position of a character in a line at a point.
    /// - Returns: `nil` if supplied point is not belong to any character in the line.
    func characterIndex(at x:CGFloat, inLineAt offset:Int, with f:NSFont) -> String.Index? {
        let x1 = x - config.breakpointWidth
        let hh = config.lineHeight / 2
        let line = source.storage.lines[offset]
        let ctline = CTLine.make(with: line.content, font: f)
        let utf16Offset = CTLineGetStringIndexForPosition(ctline, CGPoint(x: x1, y: hh))
        guard utf16Offset != kCFNotFound else { return nil }
        return line.content.utf16.index(line.content.utf16.startIndex, offsetBy: utf16Offset)
    }
    /// Finds position of a character and its line at a point.
    /// - Returns: `nil` if supplied point is not belong to any character in any line.
    func position(at p:CGPoint) -> CodeStoragePosition? {
        guard let lineIndex = lineIndex(at: p.y) else { return nil }
        guard let characterIndex = characterIndex(at: p.x, inLineAt: lineIndex, with: config.font) else { return nil }
        return CodeStoragePosition(line: lineIndex, characterIndex: characterIndex)
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
