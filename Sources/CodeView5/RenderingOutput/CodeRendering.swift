//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/5/19.
//

import Foundation
import AppKit

/// Renders `CodeSource` in a flipped space.
struct CodeRendering {
    var config = CodeConfig()
    func draw(source: CodeSource, imeState: IMEState?, in dirtyRect: CGRect, with cgctx: CGContext) {
        let h = config.rendering.lineHeight
        let visibleLineOffsets = Int(floor(dirtyRect.minY / h))..<Int(ceil(dirtyRect.maxY / h))
        let _visibleLineIndices = (source.storage.lines.startIndex+visibleLineOffsets.lowerBound)..<(source.storage.lines.startIndex+visibleLineOffsets.upperBound)
        let visibleExistingLineOffsets = source.storage.lines.indices.clamped(to: _visibleLineIndices)
        let selectedRange = source.selectionRange
        let selectionIncludedLineOffsetRange = source.selectionRange.includedLineOffsetRange
        let visibleSelectedLineOffsetRange = selectionIncludedLineOffsetRange.clamped(to: visibleLineOffsets)
        let sssn = session(source: source, ime: imeState)
        let layout = CodeLayout(config: config, source: source, imeState: imeState, boundingWidth: CGFloat(sssn.context.width))
        
        // Draw current line background.
        let f = layout.frameOfLine(at: source.caretPosition.lineOffset)
        sssn.drawBox(f, color: .unemphasizedSelectedTextBackgroundColor)
        
        // Draw breakpoints.
        for lineOffset in visibleExistingLineOffsets {
            if source.breakpointLineOffsets.contains(lineOffset) {
                let f = layout.frameOfBreakpointInLine(at: lineOffset)
                let c = config.rendering.breakPointColor
                sssn.drawBreakpoint(in: f, color: c)
            }
        }
        
        // Draw selection background.
        for lineOffset in visibleSelectedLineOffsetRange {
            let f = layout.frameOfSelectionInLine(at: lineOffset)
            sssn.drawBox(f, color: config.rendering.selectedTextBackgroundColor)
        }
        // Draw IME selection background.
        if let f = layout.frameOfIMESelection() {
            sssn.drawBox(f, color: config.rendering.selectedTextBackgroundColor)
        }
        // Draw characters.
        func charactersToDrawWithConsideringIME(of lineOffset: Int) -> Substring {
//            let lineIndex = source.storage.lines.startIndex + lineOffset
            let line = source.storage.lines.atOffset(lineOffset)
            guard let imes = imeState else { return line.content }
            guard selectedRange.upperBound.lineOffset == lineOffset else { return line.content }
            let charUTF8Offet = selectedRange.upperBound.characterUTF8Offset
            let charIndex = line.content.indexFromUTF8Offset(charUTF8Offet)
            let s = line.content.replacingCharacters(in: charIndex..<charIndex, with: imes.incompleteText)
            return s[s.startIndex...]
        }
        for lineOffset in visibleExistingLineOffsets {
            let s = charactersToDrawWithConsideringIME(of: lineOffset)
            let f = layout.frameOfTextInLine(at: lineOffset)
            sssn.drawText(s, font: config.rendering.font, color: config.rendering.textColor, in: f)
        }
        // Draw line numbers.
        for lineOffset in visibleExistingLineOffsets {
            let s = "\(lineOffset)"
            let f = layout.frameOfLineNumberArea(at: lineOffset)
            let c = config.rendering.lineNumberColor
            sssn.drawTextRightAligned(s[s.startIndex...], font: config.rendering.lineNumberFont, color: c, in: f)
        }
        
//        // Draw debug info.
//        for lineIndex in visibleExistingLineIndices {
//            let s = "\(source.storage.keys[lineIndex])"
//            sssn.drawText(s, indentation: 100, at: lineIndex)
//        }
        // Draw caret.
        if let f = layout.frameOfCaret() {
            sssn.drawBox(f, color: config.rendering.textColor)
        }
    }
    private func session(source s: CodeSource, ime: IMEState?) -> CodeRenderingSession {
        let cgctx = NSGraphicsContext.current!.cgContext
        cgctx.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
        return CodeRenderingSession(context: cgctx, source: s, imeState: ime)
    }
}
private struct CodeRenderingSession {
    let context: CGContext
    let source: CodeSource
    let imeState: IMEState?
    func drawText(_ ss:Substring, font: NSFont, color c: NSColor, in f:CGRect) {
        let ctline = CTLine.make(with: ss, font: font, color: c)
        // First line need to be moved down by line-height
        // as CG places it above zero point.
        context.textPosition = CGPoint(
            x: f.minX,
            y: font.ascender + f.minY)
        CTLineDraw(ctline, context)
    }
    func drawTextRightAligned(_ ss:Substring, font: NSFont, color c: NSColor, in f:CGRect) {
        let ctline = CTLine.make(with: ss, font: font, color: c)
        let w = ctline.bounds.width
        // First line need to be moved down by line-height
        // as CG places it above zero point.
        context.textPosition = CGPoint(
            x: f.maxX - w,
            y: font.ascender + f.minY)
        CTLineDraw(ctline, context)
    }
    func drawBreakpoint(in f:CGRect, color c:NSColor) {
        let w = f.width
        let h = f.height
        let hh = h / 2
        let x = f.minX
        let y = f.minY
        let p = CGMutablePath()
        p.move(to: .zero)
        p.addLines(between: [
            CGPoint(x: x,           y: y),
            CGPoint(x: x + w - hh,  y: y),
            CGPoint(x: x + w,       y: y + hh),
            CGPoint(x: x + w - hh,  y: y + h),
            CGPoint(x: x,           y: y + h),
        ])
        context.addPath(p)
        context.setFillColor(c.cgColor)
        context.fillPath()
    }
    func drawBox(_ f:CGRect, color c: NSColor) {
        context.setFillColor(c.cgColor)
        context.fill(f)
    }
}
