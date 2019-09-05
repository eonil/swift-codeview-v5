//
//  CodeView.swift
//  CodeView5
//
//  Created by Henry on 2019/07/25.
//  Copyright © 2019 Eonil. All rights reserved.
//

import Foundation
import Combine
import AppKit

public final class CodeView: NSView {
    private let typing = TextTyping()
    private let codeFont = NSFont(name: "SF Mono", size: NSFont.systemFontSize)!
    private var pipes = [AnyCancellable]()
    private var source = CodeSource()
    private var imeIncompleteText = IMEIncompleteText?.none
    private struct IMEIncompleteText {
        var content = ""
        var selection = Range<String.Index>(uncheckedBounds: (.zero, .zero))
    }
    
    private var moveVerticalAxisX = CGFloat?.none
    private func findAxisXForVerticalMovement() -> CGFloat {
        let p = source.caretPosition
        let line = source.storage.lines[p.line]
        let s = line[..<p.characterIndex]
        let ctline = CTLine.make(with: String(s), font: codeFont)
        let w = CTLineGetBoundsWithOptions(ctline, []).width
        return w
    }

    public enum Control {
        case setSourceURL(URL?)
        /// Pushes modified source.
//        case setSource(CodeSource)
    }

    private func install() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        typing.note
            .receive(on: ImmediateScheduler.shared)
            .sink(receiveValue: { [weak self] in self?.process($0) })
            .store(in: &pipes)
        wantsLayer = true
    }
    private func process(_ n:TextTypingNote) {
        switch n {
        case let .previewIncompleteText(content, selection):
            source.replaceCharactersInCurrentSelection(with: "")
            imeIncompleteText = IMEIncompleteText(content: content, selection: selection)
            setNeedsDisplay(bounds)
        case let .placeText(s):
            imeIncompleteText = nil
            source.replaceCharactersInCurrentSelection(with: s)
            setNeedsDisplay(bounds)
        case let .issueEditingCommand(sel):
            switch sel {
            case #selector(moveLeft(_:)):
                moveVerticalAxisX = nil
                source.moveLeft()
            case #selector(moveRight(_:)):
                moveVerticalAxisX = nil
                source.moveRight()
            case #selector(moveLeftAndModifySelection(_:)):
                moveVerticalAxisX = nil
                source.moveLeftAndModifySelection()
            case #selector(moveRightAndModifySelection(_:)):
                moveVerticalAxisX = nil
                source.moveRightAndModifySelection()
            case #selector(moveToLeftEndOfLine(_:)):
                moveVerticalAxisX = nil
                source.moveToLeftEndOfLine()
            case #selector(moveToRightEndOfLine(_:)):
                moveVerticalAxisX = nil
                source.moveToRightEndOfLine()
            case #selector(moveToLeftEndOfLineAndModifySelection(_:)):
                moveVerticalAxisX = nil
                source.moveToLeftEndOfLineAndModifySelection()
            case #selector(moveToRightEndOfLineAndModifySelection(_:)):
                moveVerticalAxisX = nil
                source.moveToRightEndOfLineAndModifySelection()
            case #selector(moveUp(_:)):
                moveVerticalAxisX = moveVerticalAxisX ?? findAxisXForVerticalMovement()
                source.moveUp(font: codeFont, at: moveVerticalAxisX!)
            case #selector(moveDown(_:)):
                moveVerticalAxisX = moveVerticalAxisX ?? findAxisXForVerticalMovement()
                source.moveDown(font: codeFont, at: moveVerticalAxisX!)
            case #selector(moveUpAndModifySelection(_:)):
                moveVerticalAxisX = moveVerticalAxisX ?? findAxisXForVerticalMovement()
                source.moveUpAndModifySelection(font: codeFont, at: moveVerticalAxisX!)
            case #selector(moveDownAndModifySelection(_:)):
                moveVerticalAxisX = moveVerticalAxisX ?? findAxisXForVerticalMovement()
                source.moveDownAndModifySelection(font: codeFont, at: moveVerticalAxisX!)
            case #selector(moveToBeginningOfDocument(_:)):
                source.moveToBeginningOfDocument()
            case #selector(moveToBeginningOfDocumentAndModifySelection(_:)):
                moveVerticalAxisX = nil
                source.moveToBeginningOfDocumentAndModifySelection()
            case #selector(moveToEndOfDocument(_:)):
                moveVerticalAxisX = nil
                source.moveToEndOfDocument()
            case #selector(moveToEndOfDocumentAndModifySelection(_:)):
                moveVerticalAxisX = nil
                source.moveToEndOfDocumentAndModifySelection()
            case #selector(selectAll(_:)):
                moveVerticalAxisX = nil
                source.selectAll()
            case #selector(insertNewline(_:)):
                moveVerticalAxisX = nil
                source.insertNewLine()
            case #selector(deleteBackward(_:)):
                moveVerticalAxisX = nil
                source.deleteBackward()
            case #selector(deleteToBeginningOfLine(_:)):
                moveVerticalAxisX = nil
                source.deleteToBeginningOfLine()
            case #selector(deleteToEndOfLine(_:)):
                moveVerticalAxisX = nil
                source.deleteToEndOfLine()
            default:
                assert(false,"Unhandled editing command: \(sel)")
            }
            setNeedsDisplay(bounds)
        }
    }
    public override init(frame f: NSRect) {
        super.init(frame: f)
        install()
    }
    public required init?(coder c: NSCoder) {
        super.init(coder: c)
        install()
    }
    public override var acceptsFirstResponder: Bool { true }
    public override func becomeFirstResponder() -> Bool {
        defer { typing.activate() }
        return super.becomeFirstResponder()
    }
    public override func resignFirstResponder() -> Bool {
        typing.deactivate()
        return super.resignFirstResponder()
    }
    public override func keyDown(with event: NSEvent) {
        typing.processKeyDown(event)
    }
    public override var intrinsicContentSize: NSSize {
        return CGSize(width: 0, height: codeFont.lineHeight)
    }
    public override var isFlipped: Bool { true }
    public override func draw(_ dirtyRect: NSRect) {
        let h = codeFont.lineHeight
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
            let ctline1 = CTLine.make(with: String(s1), font: codeFont)
            let ctline2 = CTLine.make(with: String(s2), font: codeFont)
            let lineBounds1 = CTLineGetBoundsWithOptions(ctline1, [])
            let lineBounds2 = CTLineGetBoundsWithOptions(ctline2, [])
            let bgFrame = CGRect(
                x: lineBounds1.maxX,
                y: -codeFont.descender + codeFont.lineHeight * CGFloat(lineIndex),
                width: lineBounds2.width,
                height: lineBounds2.height)
            cgctx.setFillColor(NSColor.selectedTextBackgroundColor.cgColor)
            cgctx.fill(bgFrame)
        }
        // Draw characters.
        cgctx.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
        for lineIndex in lineIndicesToDraw {
            if selectedLineRange.contains(lineIndex) {
                // Draws selected part differently.
            }
            let line = source.storage.lines[lineIndex]
            func charactersToDrawWithConsideringIME() -> String {
                guard let imeState = imeIncompleteText else { return line.utf8Characters }
                guard selectedRange.upperBound.line == lineIndex else { return line.utf8Characters }
                let chidx = selectedRange.upperBound.characterIndex
                return line.utf8Characters.replacingCharacters(in: chidx..<chidx, with: imeState.content)
            }
            let chs = charactersToDrawWithConsideringIME()
            let ctline = CTLine.make(with: chs, font: codeFont)
            // First line need to be moved down by line-height
            // as CG places it above zero point.
            cgctx.textPosition = CGPoint(x: 0, y: h + h * CGFloat(lineIndex))
            CTLineDraw(ctline, cgctx)
        }
        
        // Draw caret.
        if selectedRange.isEmpty {
            let p = source.caretPosition
            let line = source.storage.lines[p.line]
            let s = line[..<p.characterIndex]
            let ctline = CTLine.make(with: String(s), font: codeFont)
            let lineBounds = CTLineGetBoundsWithOptions(ctline, [])
            let x = lineBounds.width
            let y = -codeFont.descender + codeFont.lineHeight * CGFloat(p.line)
            let caretFrame = CGRect(x: x, y: y, width: 1, height: h)
            cgctx.setFillColor(NSColor.white.cgColor)
            cgctx.fill(caretFrame)
        }
    }
}

private extension NSFont {
    var lineHeight: CGFloat {
        return -descender + ascender
    }
}

private extension Range {
    /// Returns a smallest range that can contain both of `self` and `otherRange`.
    func smallestContainer(with otherRange:Range) -> Range {
        let a = Swift.min(lowerBound, otherRange.lowerBound)
        let b = Swift.max(upperBound, otherRange.upperBound)
        return a..<b
    }
}

