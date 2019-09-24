//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/5/19.
//

import Foundation
import AppKit

/// Renders `CodeStorage` in a flipped space.
///
/// Discussion
/// ----------
/// It seems CoreText/CoreGraphics is rasterizing every glyph for every time I call draw.
/// Therefore,
///
struct CodeRendering {
    var config: CodeConfig
    var storage: CodeStorage
    var imeState: IMEState?
    var annotation: CodeAnnotation
    var bounds: CGRect
    var scale: CGFloat
    func draw(in dirtyRect: CGRect, with cgctx: CGContext) {
        let h = config.rendering.gridFittingLineHeight
        let potentiallyVisibleLineOffsets = Int(floor(dirtyRect.minY / h))..<Int(ceil(dirtyRect.maxY / h))
        let visibleLineOffsets = storage.text.lines.offsets.clamped(to: potentiallyVisibleLineOffsets)
        
        drawText(in: dirtyRect, with: cgctx, visibleLineOffsets: visibleLineOffsets)
        drawLineNumbers(in: dirtyRect, with: cgctx, visibleLineOffsets: visibleLineOffsets)
        drawAnnotation(in: dirtyRect, with: cgctx, visibleLineOffsets: visibleLineOffsets)
    }
    private func drawText(in dirtyRect: CGRect, with cgctx: CGContext, visibleLineOffsets: Range<Int>) {
//        let selectedRange = storage.selectionRange
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
//                sssn.drawBox(f, color: config.rendering.textLineBackgroundColor)
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
        for lineOffset in visibleLineOffsets {
            let line = storage.text.lines[lineOffset]
            guard !line.characters.isEmpty else { continue }
            let lineKey = line.contentEqualityKey
            let textAreaFrame = layout.frameOfLineTextArea(at: lineOffset)
            if let ctp = CachedTextPixelsCache.sharedCodeLineCache.find(lineKey) {
                cgctx.draw(ctp, at: textAreaFrame.origin)
            }
            else {
                let s = storage.makeAttributedStringFromContentInLine(at: lineOffset, with: imeState, config: config)
                let ctLine = CTLineCreateWithAttributedString(s)
                if let ctp = cgctx.makeCachedTextPixels(config: config, scale: scale, with: ctLine) {
                    CachedTextPixelsCache.sharedCodeLineCache.insert(ctp, for: lineKey)
                    cgctx.draw(ctp, at: textAreaFrame.origin)
                }
            }
            
                // Keep this line for later layout validation.
                // sssn.drawText(s, fontAscender: config.rendering.baseFont.ascender, in: textAreaFrame)
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
            func makeCTP() -> CachedTextPixels? {
                if let ctp = CachedTextPixelsCache
                    .sharedLineNumberCache
                    .find(lineOffset) {
                    return ctp
                }
                else {
                    let ctLine = CTLine.make(
                        with: s[s.startIndex...],
                        font: config.rendering.lineNumberFont,
                        color: c)
                    guard let ctp = cgctx.makeCachedTextPixels(
                        config: config,
                        scale: scale,
                        with: ctLine) else { return nil }
                    CachedTextPixelsCache.sharedLineNumberCache.insert(ctp, for: lineOffset)
                    return ctp
                }
            }
            if let ctp = makeCTP() {
                cgctx.draw(ctp, at: f.origin)
            }
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
    /// Number of styles must be same with number of UTF-8 code units in supplied substring.
    func drawText(_ ctLine:CTLine, fontAscender: CGFloat, to ctx:CGContext) {
        // First line need to be moved down by line-height
        // as CoreGraphics places it above zero point.
        ctx.textPosition = CGPoint(
            x: 0,
            y: 0)
        CTLineDraw(ctLine, ctx)
    }
    /// Number of styles must be same with number of UTF-8 code units in supplied substring.
    func drawText(_ ctLine:CTLine, fontAscender: CGFloat, in frame:CGRect) {
        // First line need to be moved down by line-height
        // as CoreGraphics places it above zero point.
        context.textPosition = CGPoint(
            x: frame.minX,
            y: fontAscender + frame.minY)
        CTLineDraw(ctLine, context)
    }
    /// Number of styles must be same with number of UTF-8 code units in supplied substring.
    func drawText(_ x:NSAttributedString, fontAscender: CGFloat, in frame:CGRect) {
        let ctLine = CTLineCreateWithAttributedString(x)
        drawText(ctLine, fontAscender: fontAscender, in: frame)
    }
    func drawText(_ ss:Substring, font: NSFont, color c: NSColor, in frame:CGRect) {
        let s = String(ss)
        let x = NSAttributedString(string: s, attributes: [
            .font: font,
            .foregroundColor: c.cgColor,
        ])
        drawText(x, fontAscender: font.ascender, in: frame)
    }
    func drawTextRightAligned(_ ctLine:CTLine, fontAscender:CGFloat, in frame:CGRect) {
        let w = ctLine.__bounds.width
        // First line need to be moved down by line-height
        // as CG places it above zero point.
        context.textPosition = CGPoint(
            x: frame.maxX - w,
            y: fontAscender + frame.minY)
        CTLineDraw(ctLine, context)
    }
    func drawTextRightAligned(_ ss:Substring, font: NSFont, color c: NSColor, in f:CGRect) {
        let ctLine = CTLine.make(with: ss, font: font, color: c)
        drawTextRightAligned(ctLine, fontAscender: font.ascender, in: f)
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




// MARK: - IMECompositedLineCharsForDrawing
extension CodeStorage {
    func makeAttributedStringFromContentInLine(at lineOffset:Int, with imeState:IMEState?, config:CodeConfig) -> NSAttributedString {
        let s = IMECompositedLineCharsForDrawing.with(self, imeState: imeState, lineOffset: lineOffset)
        let x = NSMutableAttributedString()
        let fxs = s.fragments.map({ $0.makeAttributedString(config: config) })
        for fx in fxs {
            x.append(fx)
        }
        return x
    }
}
/// Informations need to draw characters in a line correctly with IME state.
/// - If there's any text-in-completion with IME, there will not be any selection.
/// - If there's no IME state to consider in target line, only starting characters and styles will be set.
///   - All other parameters will remain empty, but it still will yield correct drawing.
///
private struct IMECompositedLineCharsForDrawing {
    var fragments = [Fragment]()
    struct Fragment {
        var chars: Substring
        var kind: Kind
        enum Kind {
            case nonIME
            case imeUnselected
            case imeSelected
        }
        var styles: ArraySlice<CodeStyle>
        func makeAttributedString(config:CodeConfig) -> NSAttributedString {
            let x = NSMutableAttributedString(string: String(chars))
            var utf8Count = 0
            var utf16Count = 0
            for ch in chars {
                let style = styles.atOffset(utf8Count)
                let detail = config.rendering.styling[style] ?? CodeConfig.Rendering.StyleDetail()
                x.setAttributes([
                    .font: detail.font,
                    .foregroundColor: detail.color.cgColor,
                ], range: NSRange(location: utf16Count, length: ch.utf16.count))
                utf8Count += ch.utf8.count
                utf16Count += ch.utf16.count
            }
            return x
        }
    }
}
extension IMECompositedLineCharsForDrawing {
    static func with(_ storage:CodeStorage, imeState: IMEState?, lineOffset: Int) -> IMECompositedLineCharsForDrawing {
        typealias F = IMECompositedLineCharsForDrawing.Fragment
        let line = storage.text.lines.atOffset(lineOffset)
        var x = IMECompositedLineCharsForDrawing()
        if let ime = imeState, storage.caretPosition.lineOffset == lineOffset {
            let imeCharOffset = storage.caretPosition.characterUTF8Offset
            let inIMESelRange = ime.selectionInIncompleteTextAsUTF8CodeUnitOffset
            let imeText = ime.incompleteText
            let imePart1 = imeText.subcontentInUTF8OffsetRange(..<inIMESelRange.lowerBound)
            let imePart2 = imeText.subcontentInUTF8OffsetRange(inIMESelRange)
            let imePart3 = imeText.subcontentInUTF8OffsetRange(inIMESelRange.upperBound...)
            x.fragments.append(F(
                chars: line.characters.subcontentInUTF8OffsetRange(0..<imeCharOffset),
                kind: .nonIME,
                styles: line.characterStyles.subcontentInOffsetRange(0..<imeCharOffset)))
            x.fragments.append(F(
                chars: imePart1,
                kind: .imeUnselected,
                styles: CodeStyle.plain.repeatingSlice(count: inIMESelRange.lowerBound)))
            x.fragments.append(F(
                chars: imePart2,
                kind: .imeSelected,
                styles: CodeStyle.plain.repeatingSlice(count: inIMESelRange.count)))
            x.fragments.append(F(
                chars: imePart3,
                kind: .imeUnselected,
                styles: CodeStyle.plain.repeatingSlice(count: imePart3.utf8.count)))
            x.fragments.append(F(
                chars: line.characters.subcontentInUTF8OffsetRange(imeCharOffset...),
                kind: .nonIME,
                styles: line.characterStyles.subcontentInOffsetRange(imeCharOffset...)))
        }
        else {
            x.fragments.append(F(
                chars: line.characters,
                kind: .nonIME,
                styles: line.characterStyles))
        }
        return x
    }
}



