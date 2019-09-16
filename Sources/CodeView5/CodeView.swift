//
//  CodeView.swift
//  CodeView5
//
//  Created by Henry on 2019/07/25.
//  Copyright © 2019 Eonil. All rights reserved.
//

import Foundation
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
    private var editor = CodeSourceEditor()
    private var imeState = IMEState?.none
    private var timeline = CodeTimeline()
    
    /// Vertical caret movement between lines needs base X coordinate to align them on single line.
    /// Here the basis X cooridnate will be stored to provide aligned vertical movement.
    private var moveVerticalAxisX = CGFloat?.none
    private func findAxisXForVerticalMovement() -> CGFloat {
        let p = editor.caretPosition
        let line = editor.storage.lines[p.lineIndex]
        let s = line[..<p.characterIndex]
        let ctline = CTLine.make(with: s, font: editor.config.rendering.font)
        let w = CTLineGetBoundsWithOptions(ctline, []).width
        return w
    }
    
    private var rendering = CodeRendering()

// MARK: - External I/O
    public func control(_ c:Control) {
        DispatchQueue.main.async { [weak self] in
            RunLoop.main.perform { [weak self] in
                self?.process(c)
            }
        }
    }
    public enum Control {
        /// Resets whole content at once with clearing all undo/redo stack.
        case reset(CodeSource)
        /// Pushes modified source.
        /// This command keeps undo/redo stack.
        case edit(CodeSource, nameForMenu:String)
    }
    public var note: ((Note) -> Void)?
    public enum Note {
        /// Notifies view conetnt has been updated by editing action.
        /// These are actiona that create new history point in timeline.
        /// Editing of replacing characters in selected range.
        /// `storageBeforeReplacement.selectedRange` is the range gets replaced.
        /// - Note:
        ///     `CodeSource.version` can be rolled back to past one if undo has been performed.
        case editing(Editing)
        public struct Editing {
            public var replacementContent: String
            public var sourceBeforeReplacement: CodeSource
            public var sourceAfterReplacement: CodeSource
        }
        /// Notifies silent replacement of source.
        /// These are all non-editing action based replacement.
        /// As there's no editing action, we cannot notify as editing
        /// but they still should be notified.
        /// - Note:
        ///     `CodeSource.version` can be rolled back to past one if undo has been performed.
        case replaceAllSilently(CodeSource)
        /// Unhandled `cancelOperation` selector command.
        /// This command is supposed to be handled by IME at first,
        /// but when IME is inactive, this is no-op.
        /// This is sent for any interested containers.
        case cancelOperation
    }

// MARK: - Initialization
    private func install() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        typing.note = { [weak self] m in
            DispatchQueue.main.async { [weak self] in
                RunLoop.main.perform { [weak self] in
                    self?.process(m)
                }
            }
        }
        editor.source.config.rendering.font = NSFont(name: "SF Mono", size: NSFont.systemFontSize) ?? editor.source.config.rendering.font
        editor.source.config.rendering.lineNumberFont = NSFont(name: "SF Compact", size: NSFont.smallSystemFontSize) ?? editor.source.config.rendering.lineNumberFont
        editor.note = { [weak self] in self?.note?($0) }
    }
    
    // MARK: - Undo/Redo Support
    private func undoInTimeline() {
        timeline.undo()
        editor.source = timeline.currentPoint.snapshot
        undoManager?.registerUndo(withTarget: self, handler: { ss in ss.redoInTimeline() })
        undoManager?.setActionName(timeline.redoablePoints.first!.kind.nameForMenu)
        render()
    }
    private func redoInTimeline() {
        timeline.redo()
        editor.source = timeline.currentPoint.snapshot
        undoManager?.registerUndo(withTarget: self, handler: { ss in ss.undoInTimeline() })
        undoManager?.setActionName(timeline.undoablePoints.last!.kind.nameForMenu)
        render()
    }
    /// Unrecords small changed made by typing or other actions.
    ///
    /// Once end-user finished typing a line,
    /// end-user would like to undo/redo that line at once instead of undo/redo
    /// them for each characters one by one.
    /// To provide such behavior, we need to "unrecord" existing small changes
    /// made by typing small units. This method does that unrecording.
    /// You are supposed to record a new snapshot point to make
    /// large unit change.
    private func unrecordAllInsignificantTimelinePoints() {
        // Replace any existing small typing (character-level) actions
        // with single large typing action on new-line.
        let s = editor
        editor.note = nil
        while !timeline.undoablePoints.isEmpty && !timeline.currentPoint.kind.isSignificant {
            undoManager?.undo()
        }
        editor = s
    }
    /// Records a new undo point.
    ///
    /// You can treat this as a save-point. Calling undo rolls state back to latest save-point.
    /// Therefore, you are supposed to call this before making new change.
    ///
    private func recordTimePoint(as kind: CodeOperationKind) {
        timeline.record(editor.source, as: kind)
        undoManager?.registerUndo(withTarget: self, handler: { ss in ss.undoInTimeline() })
        undoManager?.setActionName(kind.nameForMenu)
    }
    
// MARK: - Rendering
    private func render() {
        // Force to resize for new source state.
        invalidateIntrinsicContentSize()
        layoutSubtreeIfNeeded()
        // Scroll current line to be visible.
        let layout = CodeLayout(config: rendering.config, source: editor.source, imeState: imeState, boundingWidth: bounds.width)
        let f = layout.frameOfLine(at: editor.source.caretPosition.lineIndex)
        scrollToVisible(f)
        setNeedsDisplay(bounds)
    }
    
// MARK: - Message Processing
    private func process(_ c:CodeView.Control) {
        switch c {
        case let .reset(s):
            undoManager?.removeAllActions()
            editor.source = s
            timeline = CodeTimeline(current: s)
        case let .edit(s,n):
            editor.source = s
            unrecordAllInsignificantTimelinePoints()
            recordTimePoint(as: .alienEditing(nameForMenu: n))
        }
        render()
    }
    private func process(_ n:TextTypingNote) {
        switch n {
        case let .previewIncompleteText(content, selection):
            editor.replaceCharactersInCurrentSelection(with: "")
            imeState = IMEState(incompleteText: content, selectionInIncompleteText: selection)
        case let .placeText(s):
            imeState = nil
            editor.replaceCharactersInCurrentSelection(with: s)
            recordTimePoint(as: .typingCharacter)
        case let .issueEditingCommand(sel):
            switch sel {
            case #selector(moveLeft(_:)):
                moveVerticalAxisX = nil
                editor.moveLeft()
            case #selector(moveRight(_:)):
                moveVerticalAxisX = nil
                editor.moveRight()
            case #selector(moveLeftAndModifySelection(_:)):
                moveVerticalAxisX = nil
                editor.moveLeftAndModifySelection()
            case #selector(moveRightAndModifySelection(_:)):
                moveVerticalAxisX = nil
                editor.moveRightAndModifySelection()
            case #selector(moveToLeftEndOfLine(_:)):
                moveVerticalAxisX = nil
                editor.moveToLeftEndOfLine()
            case #selector(moveToRightEndOfLine(_:)):
                moveVerticalAxisX = nil
                editor.moveToRightEndOfLine()
            case #selector(moveToLeftEndOfLineAndModifySelection(_:)):
                moveVerticalAxisX = nil
                editor.moveToLeftEndOfLineAndModifySelection()
            case #selector(moveToRightEndOfLineAndModifySelection(_:)):
                moveVerticalAxisX = nil
                editor.moveToRightEndOfLineAndModifySelection()
            case #selector(moveUp(_:)):
                moveVerticalAxisX = moveVerticalAxisX ?? findAxisXForVerticalMovement()
                editor.moveUp(font: editor.config.rendering.font, at: moveVerticalAxisX!)
            case #selector(moveDown(_:)):
                moveVerticalAxisX = moveVerticalAxisX ?? findAxisXForVerticalMovement()
                editor.moveDown(font: editor.config.rendering.font, at: moveVerticalAxisX!)
            case #selector(moveUpAndModifySelection(_:)):
                moveVerticalAxisX = moveVerticalAxisX ?? findAxisXForVerticalMovement()
                editor.moveUpAndModifySelection(font: editor.config.rendering.font, at: moveVerticalAxisX!)
            case #selector(moveDownAndModifySelection(_:)):
                moveVerticalAxisX = moveVerticalAxisX ?? findAxisXForVerticalMovement()
                editor.moveDownAndModifySelection(font: editor.config.rendering.font, at: moveVerticalAxisX!)
            case #selector(moveToBeginningOfDocument(_:)):
                editor.moveToBeginningOfDocument()
            case #selector(moveToBeginningOfDocumentAndModifySelection(_:)):
                moveVerticalAxisX = nil
                editor.moveToBeginningOfDocumentAndModifySelection()
            case #selector(moveToEndOfDocument(_:)):
                moveVerticalAxisX = nil
                editor.moveToEndOfDocument()
            case #selector(moveToEndOfDocumentAndModifySelection(_:)):
                moveVerticalAxisX = nil
                editor.moveToEndOfDocumentAndModifySelection()
            case #selector(selectAll(_:)):
                moveVerticalAxisX = nil
                editor.selectAll()
            case #selector(insertNewline(_:)):
                unrecordAllInsignificantTimelinePoints()
                recordTimePoint(as: .typingNewLine)
                moveVerticalAxisX = nil
                editor.insertNewLine()
            case #selector(insertTab(_:)):
                moveVerticalAxisX = nil
                editor.insertTab()
            case #selector(insertBacktab(_:)):
                moveVerticalAxisX = nil
                editor.insertBacktab()
            case #selector(deleteForward(_:)):
                moveVerticalAxisX = nil
                editor.deleteForward()
            case #selector(deleteBackward(_:)):
                moveVerticalAxisX = nil
                editor.deleteBackward()
            case #selector(deleteToBeginningOfLine(_:)):
                moveVerticalAxisX = nil
                editor.deleteToBeginningOfLine()
            case #selector(deleteToEndOfLine(_:)):
                moveVerticalAxisX = nil
                editor.deleteToEndOfLine()
            case #selector(cancelOperation(_:)):
                note?(.cancelOperation)
            /// Mysterious message sent by AppKit.
            case #selector(noop(_:)):
                break
            default:
                assert(false,"Unhandled editing command: \(sel)")
                break
            }
        }
        
        let layout = CodeLayout(config: rendering.config, source: editor.source, imeState: imeState, boundingWidth: bounds.width)
        let f  = layout.frameOfSelectionInLine(at: editor.source.caretPosition.lineIndex)
        let f1 = convert(f, to: nil)
        let f2 = window?.convertToScreen(f1) ?? .zero
        typing.control(.setTypingFrame(f2))

        render()
    }
    
// MARK: - Event Hooks
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
        let layout = CodeLayout(config: rendering.config, source: editor.source, imeState: imeState, boundingWidth: bounds.width)
        if pv.x < layout.config.rendering.breakpointWidth {
            let i = layout.clampingLineIndex(at: pv.y) 
            // Toggle breakpoint.
            editor.source.toggleBreakPoint(at: i)
        }
        else {
            let p = layout.clampingPosition(at: pv)
            editor.source.caretPosition = p
            editor.source.selectionRange = p..<p
            editor.source.selectionAnchorPosition = p
        }
        setNeedsDisplay(bounds)
    }
    public override func mouseDragged(with event: NSEvent) {
        typing.processEvent(event)
        autoscroll(with: event)
        // Update caret and selection by mouse dragging.
        let pw = event.locationInWindow
        let pv = convert(pw, from: nil)
        let layout = CodeLayout(config: rendering.config, source: editor.source, imeState: imeState, boundingWidth: bounds.width)
        let p = layout.clampingPosition(at: pv)
        let oldSource = editor
        editor.source.modifySelectionWithAnchor(to: p)
        // Render only if caret or selection has been changed.
        let isRenderingInvalidated = editor.caretPosition != oldSource.caretPosition || editor.selectionRange != oldSource.selectionRange
        if isRenderingInvalidated { setNeedsDisplay(bounds) }
    }
    public override func mouseUp(with event: NSEvent) {
        typing.processEvent(event)
        editor.selectionAnchorPosition = nil
    }
    public override func selectAll(_ sender: Any?) {
        editor.selectAll()
        render()
    }
    @IBAction
    func copy(_:AnyObject) {
        let sss = editor.source.lineContentsInCurrentSelection()
        let s = sss.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(s, forType: .string)
    }
    @IBAction
    func cut(_:AnyObject) {
        let sss = editor.source.lineContentsInCurrentSelection()
        let s = sss.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(s, forType: .string)
        editor.replaceCharactersInCurrentSelection(with: "")
        render()
    }
    @IBAction
    func paste(_:AnyObject) {
        guard let s = NSPasteboard.general.string(forType: .string) else { return }
        editor.replaceCharactersInCurrentSelection(with: s)
        recordTimePoint(as: .alienEditing(nameForMenu: "Paste"))
        render()
    }
    /// Defined to make `noop(_:)` selector to cheat compiler.
    @objc
    func noop(_:AnyObject) {}
    
    public override var intrinsicContentSize: NSSize {
        let layout = CodeLayout(config: rendering.config, source: editor.source, imeState: imeState, boundingWidth: bounds.width)
        let z = layout.measureContentSize(source: editor.source, imeState: imeState)
        return CGSize(width: 300, height: z.height)
    }
    public override var isFlipped: Bool { true }
    public override func draw(_ dirtyRect: NSRect) {
        let cgctx = NSGraphicsContext.current!.cgContext
        rendering.draw(source: editor.source, imeState: imeState, in: dirtyRect, with: cgctx)
    }
}
