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
    var config = CodeLayout.Config()
    func draw(source: CodeSource, imeState: IMEState?, in dirtyRect: CGRect, with cgctx: CGContext) {
        let h = config.lineHeight
        let visibleLineIndices = Int(floor(dirtyRect.minY / h))..<Int(ceil(dirtyRect.maxY / h))
        let visibleExistingLineIndices = source.storage.lines.indices.clamped(to: visibleLineIndices)
        let selectedRange = source.selectionRange
        let selectionIncludedLineRange = source.selectionRange.includedLineRange
        let visibleSelectedLineRange = selectionIncludedLineRange.clamped(to: visibleLineIndices)
        let sssn = session(source: source, ime: imeState)
        let layout = CodeLayout(config: config, source: source, imeState: imeState, boundingWidth: CGFloat(sssn.context.width))
        
        // Draw current line background.
        let f = layout.frameOfLine(at: source.caretPosition.line)
        sssn.drawBox(f, color: .unemphasizedSelectedTextBackgroundColor)
        
        // Draw breakpoints.
        for lineIndex in visibleExistingLineIndices {
            if source.breakpointLineIndices.contains(lineIndex) {
                let f = layout.frameOfBreakpointInLine(at: lineIndex)
                sssn.drawBreakpoint(in: f)
            }
        }
        
        // Draw selection background.
        for lineIndex in visibleSelectedLineRange {
            let f = layout.frameOfSelectionInLine(at: lineIndex)
            sssn.drawBox(f, color: .selectedTextBackgroundColor)
        }
        // Draw IME selection background.
        if let f = layout.frameOfIMESelection() {
            sssn.drawBox(f, color: .selectedTextBackgroundColor)
        }
        // Draw characters.
        func charactersToDrawWithConsideringIME(of lineIndex: Int) -> String {
            let line = source.storage.lines[lineIndex]
            guard let imes = imeState else { return line.content }
            guard selectedRange.upperBound.line == lineIndex else { return line.content }
            let chidx = selectedRange.upperBound.characterIndex
            return line.content.replacingCharacters(in: chidx..<chidx, with: imes.incompleteText)
        }
        for lineIndex in visibleExistingLineIndices {
            let s = charactersToDrawWithConsideringIME(of: lineIndex)
            let f = layout.frameOfTextInLine(at: lineIndex)
            sssn.drawText(s, in: f)
        }
        // Draw line numbers.
        for lineIndex in visibleExistingLineIndices {
            let s = "\(lineIndex)"
            let f = layout.frameOfLineNumber(at: lineIndex)
            sssn.drawText(s, in: f)
        }
        
//        // Draw debug info.
//        for lineIndex in visibleExistingLineIndices {
//            let s = "\(source.storage.keys[lineIndex])"
//            sssn.drawText(s, indentation: 100, at: lineIndex)
//        }
        // Draw caret.
        if let f = layout.frameOfCaret() {
            sssn.drawBox(f, color: .textColor)
        }
    }
    private func session(source s: CodeSource, ime: IMEState?) -> CodeRenderingSession {
        let cgctx = NSGraphicsContext.current!.cgContext
        cgctx.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
        return CodeRenderingSession(config: config, context: cgctx, source: s, imeState: ime)
    }
}
private struct CodeRenderingSession {
    let config: CodeLayout.Config
    let context: CGContext
    let source: CodeSource
    let imeState: IMEState?
    func drawText(_ s:String, color c: NSColor = .textColor, in f:CGRect) {
        let ctline = CTLine.make(with: s, font: config.font)
        // First line need to be moved down by line-height
        // as CG places it above zero point.
        context.textPosition = CGPoint(
            x: f.minX,
            y: config.font.ascender + f.minY)
        context.setFillColor(c.cgColor)
        CTLineDraw(ctline, context)
    }
    func drawBreakpoint(in f:CGRect) {
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
        context.setFillColor(NSColor.controlAccentColor.cgColor)
        context.fillPath()
    }
    func drawBox(_ f:CGRect, color c: NSColor) {
        context.setFillColor(c.cgColor)
        context.fill(f)
    }
}
