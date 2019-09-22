////
////  CodeView.swift
////  CodeView5
////
////  Created by Henry on 2019/07/25.
////  Copyright © 2019 Eonil. All rights reserved.
////
//
//import Foundation
//import AppKit
//
///// User interaction surface for code-text editing.
/////
///// `CodeView` is buildt in simple REPL.
///// - Read: `typing` manages end-user's typing input with IME support.
///// - Eval: `state` is a full value-semantic state and modifier around it.
///// - Print: Drawing method renders current `state`.
/////
///// Typing
///// ------
///// - This is pure input.
///// - Scans end-user intentions.
///// - Scanned result will be sent to `state` as messages.
///// - Typing is an independent actor.
/////
///// State
///// -----
///// - This is fully value semantic. No shared mutable reference.
///// - This is referentially transparent. Same input produces same output. No global state.
///// - State is not an independent actor. Processing is done by simple function call.
///// - State is pure value & functions. There's no concept of event.
/////
///// Rendering
///// ---------
///// - This is a pure output. Renders `source` to screen.
///// - You can consider rendering as a transformation of `state` to an opaque result value.
///// - That result you cannot access.
///// - In this case, `state` itself is the value to render.
///// - Renderering does not involve any an independent actor.
///// - Rendering is done by simple function call.
/////
///// Design Choicese
///// ---------------
///// - Prefer value-semantic and pure-functions over independent actor.
///// - Prefer function call over message passing.
///// - Prefer forward message passing over backward message passing (event emission).
/////
///// Synchronization
///// ---------------
///// Most control commands does not need synchronization
///// as they are designed as oneway streaming write commands
///// and ultimately can be performed on any state.
///// But some commands require bi-directional read/write,
///// therefore they need synchronization.
///// - Copy
///// - Cut
///// - Paste
///// - Undo
///// - Redo
///// Performing these commands with unsynchronized state can produce wrong result.
///// To support synchronization, we use "process-key"s. As each control command
///// This is especially important for your app's menu handling.
///// You also manage your app's menu to be called while this view is synchronized.
///// Use `isSynchronized` property to check whether this view is synchronized.
///// To prevent accidental such situation, this view crashes if you pass any control message
///// when unsynchronized.
//public final class CodeView: NSView, NSUserInterfaceValidations {
//    private let typing = TextTyping()
//    private var config = CodeConfig()
//    private var state = CodeState()
//    private var preventedTypingCommands = Set<TextTypingCommand>()
//
//    // MARK: - External I/O
//    
//    /// Sends control message.
//    public func control(_ c:Control) {
//        switch c {
//        case let .reset(s):
//            performEditRenderAndNote(.reset(s))
//        case let .edit(s,n):
//            performEditRenderAndNote(.edit(s, nameForMenu: n))
//        case let .setPreventedTextTypingCommands(cmds):
//            preventedTypingCommands = cmds
//        }
//    }
//    public enum Control {
//        case reset(CodeStorage)
//        /// Pushes modified source.
//        /// This command keeps undo/redo stack.
//        case edit(CodeSource, nameForMenu:String)
//        /// Prevents some typing commands.
//        /// Use this when you want to let user to move up/down in completion window.
//        case setPreventedTextTypingCommands(Set<TextTypingCommand>)
//    }
//    public var note: ((Note) -> Void)?
//    public enum Note {
//        /// Notifies view content has been updated by any editing action.
//        /// These are actions that creates new history point in timeline.
//        ///
//        /// Tracking Content Changes
//        /// ------------------------
//        /// To track contet (text) changes, see `CodeSource.timeline`.
//        /// It contains changes happen in `CodeSource.storage` since last emission.
//        /// The timeline will be emptied each time after note emission.
//        /// **If `CodeSource.timeline` is empty, it means whole snapshot replacement**.
//        /// This can happen by content reloading or undo/redo operation.
//        /// In that case, you must abandon any existing content
//        /// and should replace all from the source.
//        case editing(CodeConfig,CodeSource,IMEState?)
////        /// Notifies silent replacement of source.
////        /// These are all non-editing action based replacement.
////        /// As there's no editing action, we cannot notify as editing
////        /// but they still should be notified.
////        /// - Note:
////        ///     `CodeSource.version` can be rolled back to past one if undo has been performed.
////        /// Config and IME state are provided for layout calculation.
////        case replaceAllSilently(CodeConfig, CodeSource, IMEState)
//        
//        case becomeFirstResponder
//        case resignFirstResponder
//        /// Typing command used to update latest state.
//        case typingCommand(TextTypingCommand)
//    }
//
//    // MARK: - Initialization
//    private func install() {
//        wantsLayer = true
//        layer?.backgroundColor = NSColor.clear.cgColor
//        typing.note = { [weak self] n in self?.process(n) }
//        render(invalidatedRegion: .all)
//    }
//    private func performEditRenderAndNote(_ m:CodeUserInteractionScanningMessage.MenuMessage) {
//        switch m {
//        case .copy
//        }
//    }
//    private func performEditRenderAndNote(_ c:CodeEditing.Message) {
//        var editing = CodeEditing(config: config, state: state)
//        editing.apply(c)
//        state = editing.state
//        let sourceToNote = state.source
//        state.source.cleanTimeline()
//        /// Render after setting config/state
//        /// so they can calculate based on latest state correctly.
//        render(invalidatedRegion: editing.invalidatedRegion)
//        note?(.editing(config, sourceToNote, state.imeState))
//    }
//    
//    // MARK: - Rendering
//    private func render(invalidatedRegion: CodeEditing.InvalidatedRegion) {
//        // Force to resize for new source state.
//        invalidateIntrinsicContentSize()
//        layoutSubtreeIfNeeded()
//        // Scroll current line to be visible.
//        let layout = CodeLayout(
//            config: config,
//            source: state.source,
//            imeState: state.imeState,
//            boundingWidth: bounds.width)
//        let f = layout.frameOfLine(
//            at: state.source.caretPosition.lineOffset)
//        
//        switch invalidatedRegion {
//        case .none:
//            break
//        case let .some(invalidatedBounds):
//            setNeedsDisplay(invalidatedBounds)
//        case .all:
//            setNeedsDisplay(bounds)
//        }
//        
//        scrollToVisible(f)
//        setNeedsDisplay(bounds)
//    }
//    
//    // MARK: - Message Processing
//    private func process(_ m:TextTypingMessage) {
//        func shouldProcessMessage() -> Bool {
//            switch m {
//            case let .processEditingCommand(cmd): return !preventedTypingCommands.contains(cmd)
//            default: return true
//            }
//        }
//        
//        // Process if allowed.
//        if shouldProcessMessage() {
//            performEditRenderAndNote(.typing(m))
//            let f = state.typingFrame(config: config, in: bounds)
//            let f1 = convert(f, to: nil)
//            let f2 = window?.convertToScreen(f1) ?? .zero
//            typing.control(.setTypingFrame(f2))
//        }
//        
//        // Fire extra events.
//        switch m {
//        case let .processEditingCommand(cmd): note?(.typingCommand(cmd))
//        default: break
//        }
//    }
//    
//    // MARK: - Event Hooks
//    public override init(frame f: NSRect) {
//        super.init(frame: f)
//        install()
//    }
//    public required init?(coder c: NSCoder) {
//        super.init(coder: c)
//        install()
//    }
//    public override var acceptsFirstResponder: Bool { true }
//    public override func becomeFirstResponder() -> Bool {
//        defer {
//            typing.activate()
//            note?(.becomeFirstResponder)
//        }
//        return super.becomeFirstResponder()
//    }
//    public override func resignFirstResponder() -> Bool {
//        typing.deactivate()
//        defer {
//            note?(.resignFirstResponder)
//        }
//        return super.resignFirstResponder()
//    }
//    public override var canBecomeKeyView: Bool { true }
//    public override func keyDown(with event: NSEvent) {
//        typing.processEvent(event)
//    }
//    public override func mouseDown(with event: NSEvent) {
//        typing.processEvent(event)
//        let pw = event.locationInWindow
//        let pv = convert(pw, from: nil)
//        let mc = CodeEditing.Message.MouseMessage(
//            kind: .down,
//            pointInBounds: pv,
//            bounds: bounds)
//        performEditRenderAndNote(.mouse(mc))
//    }
//    public override func mouseDragged(with event: NSEvent) {
//        typing.processEvent(event)
//        autoscroll(with: event)
//        // Update caret and selection by mouse dragging.
//        let pw = event.locationInWindow
//        let pv = convert(pw, from: nil)
//        let mc = CodeEditing.Message.MouseMessage(
//            kind: .dragged,
//            pointInBounds: pv,
//            bounds: bounds)
//        performEditRenderAndNote(.mouse(mc))
//    }
//    public override func mouseUp(with event: NSEvent) {
//        typing.processEvent(event)
//        let pw = event.locationInWindow
//        let pv = convert(pw, from: nil)
//        let mc = CodeEditing.Message.MouseMessage(
//            kind: .up,
//            pointInBounds: pv,
//            bounds: bounds)
//        performEditRenderAndNote(.mouse(mc))
//    }
//    public override func selectAll(_ sender: Any?) {
//        performEditRenderAndNote(.selectAll)
//    }
//    @IBAction
//    func copy(_:AnyObject) {
//        let sss = state.source.lineContentsInCurrentSelection()
//        let s = sss.joined(separator: "\n")
//        NSPasteboard.general.clearContents()
//        NSPasteboard.general.setString(s, forType: .string)
//    }
//    @IBAction
//    func cut(_:AnyObject) {
//        let sss = state.source.lineContentsInCurrentSelection()
//        let s = sss.joined(separator: "\n")
//        state.source.replaceCharactersInCurrentSelection(with: "")
//        performEditRenderAndNote(.edit(state.source, nameForMenu: "Cut"))
//        NSPasteboard.general.clearContents()
//        NSPasteboard.general.setString(s, forType: .string)
//    }
//    @IBAction
//    func paste(_:AnyObject) {
//        guard let s = NSPasteboard.general.string(forType: .string) else { return }
//        state.source.replaceCharactersInCurrentSelection(with: s)
//        performEditRenderAndNote(.edit(state.source, nameForMenu: "Paste"))
//    }
//    @IBAction
//    func undo(_:AnyObject) {
//        performEditRenderAndNote(.undo)
//    }
//    @IBAction
//    func redo(_:AnyObject) {
//        performEditRenderAndNote(.redo)
//    }
//    /// Defined to make `noop(_:)` selector to cheat compiler.
//    @objc
//    func noop(_:AnyObject) {}
//    
//    public func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
//        /// Checks for synchronization state to prevent consecutive calling.
//        /// If we don't check for synchronized state, consecutive calling of these items
//        /// will prevent execution of code in other context, therefore nothing really
//        /// will be processed.
//        switch item.action {
//        case #selector(copy(_:)):
//            return true
//        case #selector(cut(_:)):
//            return true
//        case #selector(paste(_:)):
//            return true
//        case #selector(undo(_:)):
//            return state.timeline.canUndo
//        case #selector(redo(_:)):
//            return state.timeline.canRedo
//        default:
//            return true
//        }
//    }
//    public override var intrinsicContentSize: NSSize {
//        let layout = CodeLayout(
//            config: config,
//            source: state.source,
//            imeState: state.imeState,
//            boundingWidth: bounds.width)
//        let z = layout.measureContentSize(source: state.source, imeState: state.imeState)
//        return CGSize(width: 300, height: z.height)
//    }
//    public override var isFlipped: Bool { true }
//    public override func draw(_ dirtyRect: NSRect) {
//        let cgctx = NSGraphicsContext.current!.cgContext
//        var rendering = CodeRendering()
//        rendering.config = config
//        rendering.draw(source: state.source, imeState: state.imeState, in: dirtyRect, with: cgctx)
//    }
//}
//
