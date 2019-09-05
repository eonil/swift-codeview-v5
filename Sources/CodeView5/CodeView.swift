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

/// Rendering and interaction surface for code-text.
///
/// `CodeView` is builds simple REPL.
/// - Read: `typing` manages end-user's typing input with IME support.
/// - Eval: `source` is a full value-semantic state and modifier around it.
/// - Print: `rendering` manages code-text rendering. Also provides layout calculation.
///
/// Typing
/// ------
/// - This is pure input.
/// - Scans end-user intentions.
/// - Scanned result will be sent to `source` as messages.
/// - Typing is an independent actor. Messages are passed using `Combine` bidirectionally.
///
/// Source
/// ------
/// - This is fully value semantic. No shared mutable reference.
/// - This is referentially transparent. Same input produces same output. No global state.
/// - Source is not an independent actor. Processing is done by simple function call.
/// - Source is pure value & functions. There's no concept of event.
///
/// Rendering
/// ---------
/// - This is pure output. Renders `source` to screen.
/// - In this case, `source` itself becomes message to render.
/// - Renderer is not an independent actor. Rendering is done by simple function call.
///
/// Design Choicese
/// ---------------
/// - Prefer value-semantic and pure-functions over independent actor.
/// - Prefer function call over message passing.
/// - Prefer forward message passing over backward message passing (event emission).
///
public final class CodeView: NSView {
    private let typing = TextTyping()
    private var pipes = [AnyCancellable]()
    private var source = CodeSource()
    private var imeState = IMEState?.none
    
    /// Vertical caret movement between lines needs base X coordinate to align them on single line.
    /// Here the basis X cooridnate will be stored to provide aligned vertical movement.
    private var moveVerticalAxisX = CGFloat?.none
    private func findAxisXForVerticalMovement() -> CGFloat {
        let p = source.caretPosition
        let line = source.storage.lines[p.line]
        let s = line[..<p.characterIndex]
        let ctline = CTLine.make(with: String(s), font: rendering.config.font)
        let w = CTLineGetBoundsWithOptions(ctline, []).width
        return w
    }
    
    private var rendering = CodeRendering()
    
    public let control = PassthroughSubject<Control,Never>()
    public enum Control {
        /// Pushes modified source.
        case source(CodeSource)
    }
    public let note = PassthroughSubject<Note,Never>()
    public enum Note {
        case source(CodeSource)
    }

    private func install() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        typing.note
            .receive(on: ImmediateScheduler.shared)
            .sink(receiveValue: { [weak self] in self?.process($0) })
            .store(in: &pipes)
        wantsLayer = true
        rendering.config.font = NSFont(name: "SF Mono", size: NSFont.systemFontSize) ?? rendering.config.font
    }
    private func process(_ n:TextTypingNote) {
        switch n {
        case let .previewIncompleteText(content, selection):
            source.replaceCharactersInCurrentSelection(with: "")
            imeState = IMEState(incompleteText: content, selectionInIncompleteText: selection)
            setNeedsDisplay(bounds)
        case let .placeText(s):
            imeState = nil
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
                source.moveUp(font: rendering.config.font, at: moveVerticalAxisX!)
            case #selector(moveDown(_:)):
                moveVerticalAxisX = moveVerticalAxisX ?? findAxisXForVerticalMovement()
                source.moveDown(font: rendering.config.font, at: moveVerticalAxisX!)
            case #selector(moveUpAndModifySelection(_:)):
                moveVerticalAxisX = moveVerticalAxisX ?? findAxisXForVerticalMovement()
                source.moveUpAndModifySelection(font: rendering.config.font, at: moveVerticalAxisX!)
            case #selector(moveDownAndModifySelection(_:)):
                moveVerticalAxisX = moveVerticalAxisX ?? findAxisXForVerticalMovement()
                source.moveDownAndModifySelection(font: rendering.config.font, at: moveVerticalAxisX!)
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
            case #selector(insertTab(_:)):
                moveVerticalAxisX = nil
                source.insertTab()
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
                break
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
        return rendering.measureContentSize(source: source, imeState: imeState)
    }
    public override var isFlipped: Bool { true }
    public override func draw(_ dirtyRect: NSRect) {
        let cgctx = NSGraphicsContext.current!.cgContext
        rendering.draw(source: source, imeState: imeState, in: dirtyRect, with: cgctx)
    }
}

