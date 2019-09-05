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
        print(#function)
        print(n)
        switch n {
        case let .previewIncompleteText(content, selection):
            source.replaceCharactersInCurrentSelection(with: "", selection: .allOfReplacementCharacters)
            imeIncompleteText = IMEIncompleteText(content: content, selection: selection)
            setNeedsDisplay(bounds)
        case let .placeText(s):
            imeIncompleteText = nil
            source.replaceCharactersInCurrentSelection(with: s, selection: .atEndOfReplacementCharactersWithZeroLength)
            setNeedsDisplay(bounds)
        case let .issueEditingCommand(sel):
            switch sel {
//            case #selector(noop(_:)):
//                print(self)
            case #selector(insertNewline(_:)):
                source.insertNewLine()
            case #selector(deleteBackward(_:)):
                source.deleteBackward()
            default:
                assert(false,"Unhandled editing command: \(sel)")
            }
            setNeedsDisplay(bounds)
        }
        
        print(source.storageSelection)
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
        print(#function)
        let h = codeFont.lineHeight
        let visibleLineIndices = Int(floor(dirtyRect.minY / h))..<Int(ceil(dirtyRect.maxY / h))
        let lineIndicesToDraw = source.storage.lines.indices.clamped(to: visibleLineIndices)
        let selectedRange = source.storageSelection.range
        let cgctx = NSGraphicsContext.current!.cgContext
        cgctx.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
        for lineIndex in lineIndicesToDraw {
            let line = source.storage.lines[lineIndex]
            func charactersToDrawWithConsideringIME() -> String {
                guard let imeState = imeIncompleteText else { return line.utf8Characters }
                guard selectedRange.upperBound.line == lineIndex else { return line.utf8Characters }
                let chidx = selectedRange.upperBound.characterIndex
                return line.utf8Characters.replacingCharacters(in: chidx..<chidx, with: imeState.content)
            }
            let chs = charactersToDrawWithConsideringIME()
            let achs = NSAttributedString(string: chs, attributes: [
                NSAttributedString.Key.font : codeFont,
                .foregroundColor: NSColor.white,
            ])
            // First line need to be moved down by line-height
            // as CG places it above zero point.
            cgctx.textPosition = CGPoint(x: 0, y: h + h * CGFloat(lineIndex))
            let ctline = CTLineCreateWithAttributedString(achs)
            CTLineDraw(ctline, cgctx)
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
