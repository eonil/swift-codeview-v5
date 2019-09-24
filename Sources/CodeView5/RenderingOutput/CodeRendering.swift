//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/5/19.
//

import Foundation
import AppKit

/// Renders `CodeStorage` in a flipped space.
struct CodeRendering {
    var config: CodeConfig
    var storage: CodeStorage
    var imeState: IMEState?
    var annotation: CodeAnnotation
    var bounds: CGRect
    func draw(in dirtyRect: CGRect, with cgctx: CGContext) {
        let h = config.rendering.lineHeight
        let potentiallyVisibleLineOffsets = Int(floor(dirtyRect.minY / h))..<Int(ceil(dirtyRect.maxY / h))
        let visibleLineOffsets = storage.text.lines.offsets.clamped(to: potentiallyVisibleLineOffsets)
        
        drawText(in: dirtyRect, with: cgctx, visibleLineOffsets: visibleLineOffsets)
        drawAnnotation(in: dirtyRect, with: cgctx, visibleLineOffsets: visibleLineOffsets)
        drawLineNumbers(in: dirtyRect, with: cgctx, visibleLineOffsets: visibleLineOffsets)
    }
    private func drawText(in dirtyRect: CGRect, with cgctx: CGContext, visibleLineOffsets: Range<Int>) {
        let selectedRange = storage.selectionRange
        let selectionIncludedLineOffsetRange = storage.selectionRange.includedLineOffsetRange
        let visibleSelectedLineOffsetRange = selectionIncludedLineOffsetRange.clamped(to: visibleLineOffsets)
        let sssn = session(storage: storage, ime: imeState)
        let layout = CodeLayout(config: config, storage: storage, imeState: imeState, boundingWidth: CGFloat(bounds.width))
        
        // Draw line background.
        for lineOffset in visibleLineOffsets {
            let f = layout.frameOfLine(at: lineOffset)
            if lineOffset == storage.caretPosition.lineOffset {
                sssn.drawBox(f, color: config.rendering.currentTextLineBackgroundColor)
            }
            else {
                sssn.drawBox(f, color: config.rendering.textLineBackgroundColor)
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
            let line = storage.text.lines.atOffset(lineOffset)
            guard let imes = imeState else { return line.content }
            guard selectedRange.upperBound.lineOffset == lineOffset else { return line.content }
            let charUTF8Offet = selectedRange.upperBound.characterUTF8Offset
            let charIndex = line.content.indexFromUTF8Offset(charUTF8Offet)
            let s = line.content.replacingCharacters(in: charIndex..<charIndex, with: imes.incompleteText)
            return s[s.startIndex...]
        }
        for lineOffset in visibleLineOffsets {
            let s = charactersToDrawWithConsideringIME(of: lineOffset)
            let f = layout.frameOfTextInLine(at: lineOffset)
//            let c = visibleSelectedLineOffsetRange.contains(lineOffset)
//                ? config.rendering.selectedTextCharacterColor
//                : config.rendering.textColor
            let c = config.rendering.textColor
            sssn.drawText(s, font: config.rendering.font, color: c, in: f)
        }
        
//        // Draw debug info.
//        for lineIndex in visibleExistingLineIndices {
//            let s = "\(storage.storage.keys[lineIndex])"
//            sssn.drawText(s, indentation: 100, at: lineIndex)
//        }
        // Draw caret.
        if let f = layout.frameOfCaret() {
            sssn.drawBox(f, color: config.rendering.textColor)
        }
    }
    private func drawAnnotation(in dirtyRect: CGRect, with cgctx: CGContext, visibleLineOffsets: Range<Int>) {
        let sssn = session(storage: storage, ime: imeState)
        let layout = CodeLayout(config: config, storage: storage, imeState: imeState, boundingWidth: CGFloat(bounds.width))

        // Draw diagnostics.
        for lineOffset in visibleLineOffsets {
            guard let lineAnno = annotation.lineAnnotations[lineOffset] else { continue }
            let frameOfLine = layout.frameOfLine(at: lineOffset)
            if let diag = lineAnno.diagnostics.last {
                let msg = diag.message.allSubcontent()
                let font = config.rendering.annotationFont
                let subframeOfText = msg.frameOfCharactersInUTF8OffsetSubrange(
                    0..<msg.utf8.count,
                    withFont: font)
                let gap = config.rendering.annotationFont.xHeight
                let baseFrame = frameOfLine.divided(atDistance: subframeOfText.width, from: .maxXEdge).slice
                let bgFrame = baseFrame.insetBy(dx: -gap, dy: 0).offsetBy(dx: -gap, dy: 0)
                let textFrame = bgFrame.offsetBy(dx: -gap/2, dy: 0)
                switch diag.severity {
                case .info:
                    let bgColor = NSColor.white.withAlphaComponent(0.0)
                    let textColor = NSColor.white.withAlphaComponent(0.5)
                    sssn.drawRoundBox(bgFrame.insetBy(dx: gap/10, dy: gap/10), color: .black, radius: bgFrame.height/3)
                    sssn.drawBox(frameOfLine, color: bgColor)
                    sssn.drawBox(bgFrame, color: bgColor)
                    sssn.drawTextRightAligned(msg, font: font, color: textColor, in: textFrame)
                case .warn:
                    let bgColor = NSColor.white.withAlphaComponent(0.1)
                    let textColor = NSColor.white.withAlphaComponent(0.9)
                    sssn.drawBox(bgFrame, color: .black)
                    sssn.drawBox(frameOfLine, color: bgColor)
                    sssn.drawBox(bgFrame, color: bgColor)
                    sssn.drawTextRightAligned(msg, font: font, color: textColor, in: textFrame)
                case .error:
                    let bgColor = NSColor.white.withAlphaComponent(0.2)
                    let textColor = NSColor.white.withAlphaComponent(0.9)
                    sssn.drawBox(bgFrame, color: .black)
                    sssn.drawBox(frameOfLine, color: bgColor)
                    sssn.drawBox(bgFrame, color: bgColor)
                    sssn.drawTextRightAligned(msg, font: font, color: textColor, in: textFrame)
                }
            }
        }
        
        // Draw breakpoints.
        for lineOffset in visibleLineOffsets {
            if annotation.breakPoints.contains(lineOffset) {
                let f = layout.frameOfBreakpointInLine(at: lineOffset)
                let c = config.rendering.breakPointColor
                sssn.drawBreakpoint(in: f, color: c)
            }
        }
    }
    private func drawLineNumbers(in dirtyRect: CGRect, with cgctx: CGContext, visibleLineOffsets: Range<Int>) {
        let sssn = session(storage: storage, ime: imeState)
        let layout = CodeLayout(config: config, storage: storage, imeState: imeState, boundingWidth: CGFloat(bounds.width))
        // Draw line numbers.
        for lineOffset in visibleLineOffsets {
            let s = "\(lineOffset)"
            let f = layout.frameOfLineNumberArea(at: lineOffset)
            let isOnBreakPoint = annotation.breakPoints.contains(lineOffset)
            let c = isOnBreakPoint ? config.rendering.lineNumberColorOnBreakPoint : config.rendering.lineNumberColor
            sssn.drawTextRightAligned(s[s.startIndex...], font: config.rendering.lineNumberFont, color: c, in: f)
        }
    }
    private func session(storage s: CodeStorage, ime: IMEState?) -> CodeRenderingSession {
        let cgctx = NSGraphicsContext.current!.cgContext
        cgctx.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
        return CodeRenderingSession(context: cgctx, storage: s, imeState: ime)
    }
}
private struct CodeRenderingSession {
    let context: CGContext
    let storage: CodeStorage
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
    func drawRoundBox(_ f:CGRect, color c: NSColor, radius: CGFloat) {
        let p = CGPath(roundedRect: f, cornerWidth: radius, cornerHeight: radius, transform: nil)
        context.addPath(p)
        context.setFillColor(c.cgColor)
        context.fillPath()
    }
}
