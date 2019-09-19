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
/// `CodeView` is buildt in simple REPL.
/// - Read: `typing` manages end-user's typing input with IME support.
/// - Eval: `state` is a full value-semantic state and modifier around it.
/// - Print: Drawing method renders current `state`.
///
/// Typing
/// ------
/// - This is pure input.
/// - Scans end-user intentions.
/// - Scanned result will be sent to `state` as messages.
/// - Typing is an independent actor.
///
/// State
/// -----
/// - This is fully value semantic. No shared mutable reference.
/// - This is referentially transparent. Same input produces same output. No global state.
/// - State is not an independent actor. Processing is done by simple function call.
/// - State is pure value & functions. There's no concept of event.
///
/// Rendering
/// ---------
/// - This is a pure output. Renders `source` to screen.
/// - You can consider rendering as a transformation of `state` to an opaque result value.
/// - That result you cannot access.
/// - In this case, `state` itself is the value to render.
/// - Renderering does not involve any an independent actor.
/// - Rendering is done by simple function call.
///
/// Design Choicese
/// ---------------
/// - Prefer value-semantic and pure-functions over independent actor.
/// - Prefer function call over message passing.
/// - Prefer forward message passing over backward message passing (event emission).
///
/// Synchronization
/// ---------------
/// Most control commands does not need synchronization
/// as they are designed as oneway streaming write commands
/// and ultimately can be performed on any state.
/// But some commands require bi-directional read/write,
/// therefore they need synchronization.
/// - Copy
/// - Cut
/// - Paste
/// - Undo
/// - Redo
/// Performing these commands with unsynchronized state can produce wrong result.
/// To support synchronization, we use "process-key"s. As each control command
/// This is especially important for your app's menu handling.
/// You also manage your app's menu to be called while this view is synchronized.
/// Use `isSynchronized` property to check whether this view is synchronized.
/// To prevent accidental such situation, this view crashes if you pass any control message
/// when unsynchronized.
public final class CodeView: NSView, NSUserInterfaceValidations {
    private let typing = TextTyping()
    private let management = CodeManagement()
    private var config = CodeConfig()
    private var state = CodeState()
    
    private var processKeySeed = 0
    private var latestSentProcessKey = 0
    private var latestReceivedProcessKey = 0
    public var isSynchronized: Bool { latestSentProcessKey == latestReceivedProcessKey }

    // MARK: - External I/O
    /// Sends control message. **You can send control message only when `isSynchronized == true`.**
    /// Defer or cancel sending control messages if `isSynchronized == false`.
    public func control(_ c:Control) {
        precondition(isSynchronized)
        switch c {
        case let .reset(s):     sendManagementControl(.reset(s))
        case let .edit(s,n):    sendManagementControl(.edit(s, nameForMenu: n))
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
        /// Notifies view content has been updated by any editing action.
        /// These are actions that creates new history point in timeline.
        ///
        /// Tracking Content Changes
        /// ------------------------
        /// To track contet (text) changes, see `CodeSource.timeline`.
        /// It contains changes happen in `CodeSource.storage` since last emission.
        /// The timeline will be emptied each time after note emission.
        /// **If `CodeSource.timeline` is empty, it means whole snapshot replacement**.
        /// This can happen by content reloading or undo/redo operation.
        /// In that case, you must abandon any existing content
        /// and should replace all from the source.
        case editing(CodeSource)
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
        typing.note = { [weak self] n in
            DispatchQueue.main.async { [weak self] in
                RunLoop.main.perform(inModes: [.common]) { [weak self] in
                    self?.process(n)
                }
            }
        }
        management.note = { [weak self] n in
            DispatchQueue.main.async { [weak self] in
                RunLoop.main.perform(inModes: [.common]) { [weak self] in
                    self?.process(n)
                }
            }
        }
    }
    private func process(_ n:CodeManagement.Note) {
        config = n.config
        state = n.state
        /// Render after setting config/state
        /// so they can calculate based on latest state correctly.
        render(invalidatedRegion: n.invalidatedRegion)
        note?(.editing(state.source))
        latestReceivedProcessKey = n.key
    }
    /// Central procesure to perform an editing.
    private func sendManagementControl(_ c:CodeEditing.Control) {
        processKeySeed += 1
        latestSentProcessKey = processKeySeed
        management.control(c, with: latestSentProcessKey)
    }
    
    // MARK: - Rendering
    private func render(invalidatedRegion: CodeEditing.InvalidatedRegion) {
        // Force to resize for new source state.
        invalidateIntrinsicContentSize()
        layoutSubtreeIfNeeded()
        // Scroll current line to be visible.
        let layout = CodeLayout(
            config: config,
            source: state.source,
            imeState: state.imeState,
            boundingWidth: bounds.width)
        let f = layout.frameOfLine(
            at: state.source.caretPosition.lineIndex)
        
        switch invalidatedRegion {
        case .none:
            break
        case let .some(invalidatedBounds):
            setNeedsDisplay(invalidatedBounds)
        case .all:
            setNeedsDisplay(bounds)
        }
        
        scrollToVisible(f)
        setNeedsDisplay(bounds)
    }
    
    // MARK: - Message Processing
    private func process(_ n:TextTypingNote) {
        sendManagementControl(.textTyping(n))
        let f = state.typingFrame(config: config, in: bounds)
        let f1 = convert(f, to: nil)
        let f2 = window?.convertToScreen(f1) ?? .zero
        typing.control(.setTypingFrame(f2))
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
        let mc = CodeEditing.Control.MouseNote(
            kind: .down,
            pointInBounds: pv,
            bounds: bounds)
        sendManagementControl(.mouse(mc))
    }
    public override func mouseDragged(with event: NSEvent) {
        typing.processEvent(event)
        autoscroll(with: event)
        // Update caret and selection by mouse dragging.
        let pw = event.locationInWindow
        let pv = convert(pw, from: nil)
        let mc = CodeEditing.Control.MouseNote(
            kind: .dragged,
            pointInBounds: pv,
            bounds: bounds)
        sendManagementControl(.mouse(mc))
    }
    public override func mouseUp(with event: NSEvent) {
        typing.processEvent(event)
        let pw = event.locationInWindow
        let pv = convert(pw, from: nil)
        let mc = CodeEditing.Control.MouseNote(
            kind: .up,
            pointInBounds: pv,
            bounds: bounds)
        sendManagementControl(.mouse(mc))
    }
    public override func selectAll(_ sender: Any?) {
        sendManagementControl(.selectAll)
    }
    @IBAction
    func copy(_:AnyObject) {
        assert(isSynchronized)
        guard isSynchronized else { return }
        let sss = state.source.lineContentsInCurrentSelection()
        let s = sss.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(s, forType: .string)
    }
    @IBAction
    func cut(_:AnyObject) {
        assert(isSynchronized)
        guard isSynchronized else { return }
        let sss = state.source.lineContentsInCurrentSelection()
        let s = sss.joined(separator: "\n")
        state.source.replaceCharactersInCurrentSelection(with: "")
        sendManagementControl(.edit(state.source, nameForMenu: "Cut"))
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(s, forType: .string)
    }
    @IBAction
    func paste(_:AnyObject) {
        assert(isSynchronized)
        guard isSynchronized else { return }
        guard let s = NSPasteboard.general.string(forType: .string) else { return }
        state.source.replaceCharactersInCurrentSelection(with: s)
        sendManagementControl(.edit(state.source, nameForMenu: "Paste"))
    }
    @IBAction
    func undo(_:AnyObject) {
        assert(isSynchronized)
        guard isSynchronized else { return }
        sendManagementControl(.tryUndo)
    }
    @IBAction
    func redo(_:AnyObject) {
        assert(isSynchronized)
        guard isSynchronized else { return }
        sendManagementControl(.tryRedo)
    }
    /// Defined to make `noop(_:)` selector to cheat compiler.
    @objc
    func noop(_:AnyObject) {}
    
    public func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        /// Checks for synchronization state to prevent consecutive calling.
        /// If we don't check for synchronized state, consecutive calling of these items
        /// will prevent execution of code in other context, therefore nothing really
        /// will be processed.
        switch item.action {
        case #selector(copy(_:)):
            return isSynchronized
        case #selector(cut(_:)):
            return isSynchronized
        case #selector(paste(_:)):
            return isSynchronized
        case #selector(undo(_:)):
            return isSynchronized && state.timeline.canUndo
        case #selector(redo(_:)):
            return isSynchronized && state.timeline.canRedo
        default:
            return true
        }
    }
    public override var intrinsicContentSize: NSSize {
        let layout = CodeLayout(
            config: config,
            source: state.source,
            imeState: state.imeState,
            boundingWidth: bounds.width)
        let z = layout.measureContentSize(source: state.source, imeState: state.imeState)
        return CGSize(width: 300, height: z.height)
    }
    public override var isFlipped: Bool { true }
    public override func draw(_ dirtyRect: NSRect) {
        let cgctx = NSGraphicsContext.current!.cgContext
        var rendering = CodeRendering()
        rendering.config = config
        rendering.draw(source: state.source, imeState: state.imeState, in: dirtyRect, with: cgctx)
    }
}
