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
    private var timeline = CodeTimeline()
    
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

// MARK: - External I/O
    public let control = PassthroughSubject<Control,Never>()
    public enum Control {
        /// Pushes modified source.
        case source(CodeSource)
    }
    public let note = PassthroughSubject<Note,Never>()
    public enum Note {
        case source(CodeSource)
    }

// MARK: - Initialization
    private func install() {
        wantsLayer = true
        typing.note
            .receive(on: ImmediateScheduler.shared)
            .sink(receiveValue: { [weak self] in self?.process($0) })
            .store(in: &pipes)
        rendering.config.font = NSFont(name: "SF Mono", size: NSFont.systemFontSize) ?? rendering.config.font
    }
    
    // MARK: - Undo/Redo Support
    private func undoInTimeline() {
        timeline.undo()
        source = timeline.currentPoint.snapshot
        undoManager?.registerUndo(withTarget: self, handler: { ss in ss.redoInTimeline() })
        undoManager?.setActionName(timeline.redoablePoints.first!.kind.nameForMenu)
        render()
    }
    private func redoInTimeline() {
        timeline.redo()
        source = timeline.currentPoint.snapshot
        undoManager?.registerUndo(withTarget: self, handler: { ss in ss.undoInTimeline() })
        undoManager?.setActionName(timeline.undoablePoints.last!.kind.nameForMenu)
        render()
    }
    /// Unrecords small changed made by typing or other actions.
    ///
    /// Once end-user finished typing a line or large unit of text,
    /// end-user would like to undo/redo that line at once instead of undo/redo
    /// them for each characters one by one.
    /// To provide such behavior, we need to "unrecord" existing small changes
    /// made by typing small units. This method does that unrecording.
    /// You are supposed to record a new snapshot point to make
    /// large unit change.
    private func unrecordAllInsignificantTimelinePoints() {
        // Replace any existing small typing (character-level) actions
        // with single large typing action on new-line.
        let s = source
        while !timeline.undoablePoints.isEmpty && !timeline.currentPoint.kind.isSignificant {
            undoManager?.undo()
        }
        source = s
    }
    /// Records a new undo point.
    ///
    /// You are supposed to call this function BEFORE making next changes.
    ///
    private func recordTimePoint(as kind: CodeOperationKind) {
        timeline.record(source, as: kind)
        undoManager?.registerUndo(withTarget: self, handler: { ss in ss.undoInTimeline() })
        undoManager?.setActionName(kind.nameForMenu)
    }
    
// MARK: - Rendering
    private func render() {
        // Force to resize for new source state.
        invalidateIntrinsicContentSize()
        layoutSubtreeIfNeeded()
        // Scroll current line to be visible.
        let layout = CodeLayout(config: rendering.config, source: source, imeState: imeState, boundingWidth: bounds.width)
        let f = layout.frameOfLine(at: source.caretPosition.line)
        scrollToVisible(f)
        setNeedsDisplay(bounds)
    }
    
// MARK: - Note Processing
    private func process(_ n:TextTypingNote) {
        switch n {
        case let .previewIncompleteText(content, selection):
            source.replaceCharactersInCurrentSelection(with: "")
            imeState = IMEState(incompleteText: content, selectionInIncompleteText: selection)
        case let .placeText(s):
            imeState = nil
            source.replaceCharactersInCurrentSelection(with: s)
            recordTimePoint(as: .typingCharacter)
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
                unrecordAllInsignificantTimelinePoints()
                recordTimePoint(as: .typingNewLine)
                moveVerticalAxisX = nil
                source.insertNewLine()
            case #selector(insertTab(_:)):
                moveVerticalAxisX = nil
                source.insertTab()
            case #selector(insertBacktab(_:)):
                moveVerticalAxisX = nil
                source.insertBacktab()
            case #selector(deleteForward(_:)):
                moveVerticalAxisX = nil
                source.deleteForward()
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
//                assert(false,"Unhandled editing command: \(sel)")
                break
            }
        }
        
        let layout = CodeLayout(config: rendering.config, source: source, imeState: imeState, boundingWidth: bounds.width)
        let f  = layout.frameOfSelectionInLine(at: source.caretPosition.line)
        let f1 = convert(f, to: nil)
        let f2 = window?.convertToScreen(f1) ?? .zero
        typing.control.send(.setTypingFrame(f2))

        render()
        // Dispatch note.
        note.send(.source(source))
    }
    
// MARK: - Method Overridings
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
        typing.processEvent(event)
    }
    public override func mouseDown(with event: NSEvent) {
        typing.processEvent(event)
        let pw = event.locationInWindow
        let pv = convert(pw, from: nil)
        let layout = CodeLayout(config: rendering.config, source: source, imeState: imeState, boundingWidth: bounds.width)
        if pv.x < layout.config.breakpointWidth {
            let i = layout.clampingLineIndex(at: pv.y) 
            // Toggle breakpoint.
            source.toggleBreakPoint(at: i)
        }
        else {
            let p = layout.clampingPosition(at: pv)
            source.caretPosition = p
            source.selectionRange = p..<p
            source.selectionAnchorPosition = p
        }
        setNeedsDisplay(bounds)
        note.send(.source(source))
    }
    public override func mouseDragged(with event: NSEvent) {
        typing.processEvent(event)
        autoscroll(with: event)
        // Update caret and selection by mouse dragging.
        let pw = event.locationInWindow
        let pv = convert(pw, from: nil)
        let layout = CodeLayout(config: rendering.config, source: source, imeState: imeState, boundingWidth: bounds.width)
        let p = layout.clampingPosition(at: pv)
        let oldSource = source
        source.modifySelectionWithAnchor(to: p)
        // Render only if caret or selection has been changed.
        let isRenderingInvalidated = source.caretPosition != oldSource.caretPosition || source.selectionRange != oldSource.selectionRange
        if isRenderingInvalidated { setNeedsDisplay(bounds) }
        note.send(.source(source))
    }
    public override func mouseUp(with event: NSEvent) {
        typing.processEvent(event)
        source.selectionAnchorPosition = nil
        note.send(.source(source))
    }
    
    public override var intrinsicContentSize: NSSize {
        let layout = CodeLayout(config: rendering.config, source: source, imeState: imeState, boundingWidth: bounds.width)
        let z = layout.measureContentSize(source: source, imeState: imeState)
        return CGSize(width: 300, height: z.height)
    }
    public override var isFlipped: Bool { true }
    public override func draw(_ dirtyRect: NSRect) {
        let cgctx = NSGraphicsContext.current!.cgContext
        rendering.draw(source: source, imeState: imeState, in: dirtyRect, with: cgctx)
    }
}
