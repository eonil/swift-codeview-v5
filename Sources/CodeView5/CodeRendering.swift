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
    var config = Config()
    struct Config {
        /// Treats font object as a value.
        var font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
    }
    func measureContentSize(source :CodeSource, imeState: IMEState?) -> CGSize {
        return CGSize(width: 0, height: config.font.lineHeight * CGFloat(source.storage.lines.count))
    }
    func draw(source :CodeSource, imeState: IMEState?, in dirtyRect: CGRect, with cgctx: CGContext) {
        let h = config.font.lineHeight
        let visibleLineIndices = Int(floor(dirtyRect.minY / h))..<Int(ceil(dirtyRect.maxY / h))
        let lineIndicesToDraw = source.storage.lines.indices.clamped(to: visibleLineIndices)
        let selectedRange = source.selectionRange
        let selectedLineRange = source.selectionLineRange
        let visibleSelectedLineRange = selectedLineRange.clamped(to: visibleLineIndices)
        let cgctx = NSGraphicsContext.current!.cgContext
        
        // Draw selection background.
        for lineIndex in visibleSelectedLineRange {
            let r = source.selectionRange
            let line = source.storage.lines[lineIndex]
            let i0 = r.lowerBound.line == lineIndex ? r.lowerBound.characterIndex : line.startIndex
            let i1 = r.upperBound.line == lineIndex ? r.upperBound.characterIndex : line.endIndex
            let s1 = line[..<i0]
            let s2 = line[i0..<i1]
            let ctline1 = CTLine.make(with: String(s1), font: config.font)
            let ctline2 = CTLine.make(with: String(s2), font: config.font)
            let lineBounds1 = CTLineGetBoundsWithOptions(ctline1, [])
            let lineBounds2 = CTLineGetBoundsWithOptions(ctline2, [])
            let bgFrame = CGRect(
                x: lineBounds1.maxX,
                y: config.font.lineHeight * CGFloat(lineIndex),
                width: lineBounds2.width,
                height: lineBounds2.height)
            cgctx.setFillColor(NSColor.selectedTextBackgroundColor.cgColor)
            cgctx.fill(bgFrame)
        }
        // Draw characters.
        cgctx.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
        for lineIndex in lineIndicesToDraw {
            let line = source.storage.lines[lineIndex]
            func charactersToDrawWithConsideringIME() -> String {
                guard let imes = imeState else { return line.content }
                guard selectedRange.upperBound.line == lineIndex else { return line.content }
                let chidx = selectedRange.upperBound.characterIndex
                return line.content.replacingCharacters(in: chidx..<chidx, with: imes.incompleteText)
            }
            let chs = charactersToDrawWithConsideringIME()
            let ctline = CTLine.make(with: chs, font: config.font)
            // First line need to be moved down by line-height
            // as CG places it above zero point.
            cgctx.textPosition = CGPoint(x: 0, y: config.font.ascender + config.font.lineHeight * CGFloat(lineIndex))
            CTLineDraw(ctline, cgctx)
        }
        
        // Draw caret.
        if selectedRange.isEmpty {
            let p = source.caretPosition
            let line = source.storage.lines[p.line]
            let s = line[..<p.characterIndex]
            let ctline = CTLine.make(with: String(s), font: config.font)
            let lineBounds = CTLineGetBoundsWithOptions(ctline, [])
            let x = lineBounds.width
            let y = config.font.lineHeight * CGFloat(p.line)
            let caretFrame = CGRect(x: x, y: y, width: 1, height: h)
            cgctx.setFillColor(NSColor.textColor.cgColor)
            cgctx.fill(caretFrame)
        }
    }
}

private extension NSFont {
    var lineHeight: CGFloat {
        return -descender + ascender
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
//
