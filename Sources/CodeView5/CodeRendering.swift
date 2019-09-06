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
    func measureContentSize(source :CodeSource, imeState: IMEState?) -> CGSize {
        return CGSize(width: 0, height: config.lineHeight * CGFloat(source.storage.lines.count))
    }
    func draw(source: CodeSource, imeState: IMEState?, in dirtyRect: CGRect, with cgctx: CGContext) {
        let h = config.lineHeight
        let visibleLineIndices = Int(floor(dirtyRect.minY / h))..<Int(ceil(dirtyRect.maxY / h))
        let visibleExistingLineIndices = source.storage.lines.indices.clamped(to: visibleLineIndices)
        let selectedRange = source.selectionRange
        let selectedLineRange = source.selectionLineRange
        let visibleSelectedLineRange = selectedLineRange.clamped(to: visibleLineIndices)
        let sssn = session(source: source, ime: imeState)
        let layout = CodeLayout(config: config, source: source, imeState: imeState, boundingWidth: CGFloat(sssn.context.width))
        
        // Draw current line background.
        let f = layout.frameOfLine(at: source.caretPosition.line)
        sssn.drawBox(f, color: .unemphasizedSelectedTextBackgroundColor)
        
        // Draw breakpoints.
        for lineIndex in visibleExistingLineIndices {
            if source.storage.containsBreakPoint(at: lineIndex) {
                let f = layout.frameOfBreakpointInLine(at: lineIndex)
                sssn.drawBreakpoint(in: f)
            }
        }
        
        // Draw selection background.
        for lineIndex in visibleSelectedLineRange {
            let r = source.selectionRange
            let line = source.storage.lines[lineIndex]
            let i0 = r.lowerBound.line == lineIndex ? r.lowerBound.characterIndex : line.startIndex
            let i1 = r.upperBound.line == lineIndex ? r.upperBound.characterIndex : line.endIndex
            let f = layout.frameOfTextSubrange(i0..<i1, inLineAt: lineIndex)
            sssn.drawBox(f, color: .selectedTextBackgroundColor)
        }
        // Draw IME selection background.
        if let imes = imeState {
            let p = source.caretPosition
            let line = source.storage.lines[p.line]
            let ci = p.characterIndex
            var s = line.content
            let ss = s[..<p.characterIndex]
            let ss1 = ss.appending(imes.incompleteText)
            let utf8OffsetRange = imes.selectionInIncompleteTextAsUTF8CodeUnitOffset
            let a = ss1.utf8.index(ss1.startIndex, offsetBy: ss.utf8.count + utf8OffsetRange.lowerBound)
            let b = ss1.utf8.index(ss1.startIndex, offsetBy: ss.utf8.count + utf8OffsetRange.upperBound)
            let r = a..<b
            let xy = CGPoint(x: 0, y: config.lineHeight * CGFloat(p.line))
            sssn.drawSelectionBackground(of: ss1, in: r, at: xy)
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
            sssn.drawText(s, at: lineIndex)
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
    func drawText(_ s:String, color c: NSColor = .textColor, indentation x: CGFloat = 0, at lineOffset: Int) {
        let ctline = CTLine.make(with: s, font: config.font)
        // First line need to be moved down by line-height
        // as CG places it above zero point.
        context.textPosition = CGPoint(
            x: config.breakpointWidth + x,
            y: config.font.ascender + config.lineHeight * CGFloat(lineOffset))
        context.setFillColor(c.cgColor)
        CTLineDraw(ctline, context)
    }
    /// - Parameter p: Offset to place bacground.
    func drawSelectionBackground(of s:String, in r:Range<String.Index>, at p:CGPoint) {
        let s1 = s[..<r.lowerBound]
        let s2 = s[r.lowerBound..<r.upperBound]
        let ctline1 = CTLine.make(with: String(s1), font: config.font)
        let ctline2 = CTLine.make(with: String(s2), font: config.font)
        let lineBounds1 = CTLineGetBoundsWithOptions(ctline1, [])
        let lineBounds2 = CTLineGetBoundsWithOptions(ctline2, [])
        let bgFrame = CGRect(
            x: lineBounds1.maxX + p.x,
            y: p.y,
            width: lineBounds2.width,
            height: lineBounds2.height)
        drawBox(bgFrame, color: .selectedTextBackgroundColor)
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


//private extension Range {
//    /// Returns a smallest range that can contain both of `self` and `otherRange`.
//    func smallestContainer(with otherRange:Range) -> Range {
//        let a = Swift.min(lowerBound, otherRange.lowerBound)
//        let b = Swift.max(upperBound, otherRange.upperBound)
//        return a..<b
//    }
//}

