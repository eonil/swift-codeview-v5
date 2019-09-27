//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/20/19.
//

import Foundation
import AppKit

/// User interaction surface for code-text editing.
///
/// This is just a dumb terminal for code text editing.
/// You are supposed to implement your own editing engine and process
/// scanned input to render specific output.
///
/// This scans user input and renders output on screen.
/// Though it's possible to make two dedicated view for input and output,
/// it is simpler to maintain single view for input/output.
/// Also this is easier to use. You don't have to think about coordinate synchronization.
///
/// - User input will be notified using `note` function. Set a handler there.
/// - Rendering will be done by calling `control` function. You call it with a `CodeConfig` and `CodeState`.
///
/// By default, this view **does nothing**.
/// - View scans user input but you need to set `note` to handle it.
/// - View renders state output but you need to call `control` to render them.
/// This view expects external manager performs actual code-editing and calling
/// `control` method with result.
///
/// Undo/Redo
/// ---------
/// This does not use AppKit default menu handling of undo/redo.
/// You need to manage undo/redo menu yourself.
/// I recommend the one of container view to implement custom undo/redo handling.
/// See `DemoView` for how you can implement it.
///
/// Asynchronicity
/// --------------
/// Input scanning and output rendering doesn't have to be synchronous.
/// Remeber that this view is just simple grouping of two different views; (1) input scanner, (2) output renderer.
/// User can issue any command for whatever editing state. It's code editing engine's responsibility
/// how to deal with them.
///
/// If rendering gets delayed a lot, user can make wrong decision on editing command.
/// Therefore, editing engine should call rendering control ASAP. Typically, more than 10ms latency
/// is considered too slow.
///
/// Anyway, **as AppKit expects every update to be done synchronously**,
/// you'll get weird bahavior if you run processing asynchrounously.
/// For example, there's live-resizing.
/// As AppKit prevents running of GCDQ except synchronous main queue,
/// any asynchronous work simply won't work while you're resizing.
/// Though I am not sure how to avoid this, but I think there must be a way.
/// Implement it if we can find out one.
/// At this point, you have to run processing loop synchronously to avoid this.
///
@IBDesignable
public final class CodeView: NSView {
    private let completionWindowManagement = CompletionWindowManagement()
    private let typing = TextTyping()
    /// Latest rendered editing state.
    private var editing = CodeEditing()
    private var annotation = CodeAnnotation()

    // MARK: - External I/O
    /// A view to be contained in completion window if the window becomes visible.
    @IBOutlet
    public var completionView: NSView? {
        get { completionWindowManagement.completionView }
        set(x) { completionWindowManagement.completionView = x }
    }
    public enum Control {
        /// Render editing state on client side.
        case renderEditing(CodeEditing)
        case renderAnnotation(CodeAnnotation)
        /// Render completion window state.
        /// Defines whow completion window to be rendered.
        /// `nil` means completion window should be disappeared.
        /// - Note:
        ///     Default text processing engine `CodeEditing`
        ///     doesn't deal with completion window at all.
        ///     You need to deal with them yourself if you want.
        ///     Or you can use `CodeView2Management`
        ///     that also deals with completion window.
        case renderCompletionWindow(around: Range<CodeStoragePosition>?)
    }
    /// Sends control message.
    public func control(_ m:Control) {
        process(m)
    }
    public var note: ((Note) -> Void)?
    public typealias Note = CodeEditingMessage
    
    // MARK: - Initialization
    private func install() {
        wantsLayer = true
        canDrawConcurrently = true
        layer?.backgroundColor = NSColor.clear.cgColor
        typing.note = { [weak self] n in self?.note?(.typing(n)); () }
        completionWindowManagement.codeView = self
    }
    
    // MARK: -
    private func process(_ m:Control) {
        switch m {
        case let .renderEditing(mm):
            editing = mm
            do {
                let f = editing.typingFrame(in: bounds)
                let f1 = convert(f, to: nil)
                let f2 = window?.convertToScreen(f1) ?? .zero
                typing.control(.setTypingFrame(f2))
            }
            do {
                // Force to resize for new source state.
                invalidateIntrinsicContentSize()
                layoutSubtreeIfNeeded()
                switch editing.invalidatedRegion {
                case .none:                 break
                case let .some(subbounds):  setNeedsDisplay(subbounds)
                case .all:                  setNeedsDisplay(bounds)
                }
            }
            
        case let .renderAnnotation(mm):
            annotation = mm
            let layout = editing.makeLayout(in: bounds.width)
            /// - TODO: Optimize using binary search.
            for lineOffset in mm.lineAnnotations.keys {
                let f = layout.frameOfLine(at: lineOffset)
                setNeedsDisplay(f)
            }
            
        case let .renderCompletionWindow(mm):
            typealias CWS = CompletionWindowManagement.State
            let cs = mm == nil ? CWS?.none : CWS(
                config: editing.config,
                source: editing.storage,
                imeState: editing.imeState,
                completionRange: mm!)
            completionWindowManagement.setState(cs)
        }
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
    public override var undoManager: UndoManager? { nil }
    public override var acceptsFirstResponder: Bool { true }
    public override func becomeFirstResponder() -> Bool {
        defer { typing.activate() }
        return super.becomeFirstResponder()
    }
    public override func resignFirstResponder() -> Bool {
        typing.deactivate()
        return super.resignFirstResponder()
    }
    public override var canBecomeKeyView: Bool { true }
    public override func keyDown(with event: NSEvent) {
        typing.processEvent(event)
    }
    public override func viewDidHide() {
        super.viewDidHide()
    }
    public override func viewDidUnhide() {
        super.viewDidUnhide()
    }
    
    public override func mouseDown(with event: NSEvent) {
        typing.processEvent(event)
        let pw = event.locationInWindow
        let pv = convert(pw, from: nil)
        let mm = CodeEditing.Message.MouseMessage(
            kind: .down,
            pointInBounds: pv,
            bounds: bounds)
        note?(.mouse(mm))
    }
    public override func mouseDragged(with event: NSEvent) {
        typing.processEvent(event)
        autoscroll(with: event)
        // Update caret and selection by mouse dragging.
        let pw = event.locationInWindow
        let pv = convert(pw, from: nil)
        let mm = CodeEditing.Message.MouseMessage(
            kind: .dragged,
            pointInBounds: pv,
            bounds: bounds)
        note?(.mouse(mm))
    }
    public override func mouseUp(with event: NSEvent) {
        typing.processEvent(event)
        let pw = event.locationInWindow
        let pv = convert(pw, from: nil)
        let mm = CodeEditing.Message.MouseMessage(
            kind: .up,
            pointInBounds: pv,
            bounds: bounds)
        note?(.mouse(mm))
    }
    /// Defined to make `noop(_:)` selector to cheat compiler.
    @objc
    func noop(_:AnyObject) {}
    
    public override var intrinsicContentSize: NSSize {
        let layout = editing.makeLayout(in: bounds.width)
        let z = layout.measureContentSize(
            storage: editing.storage,
            imeState: editing.imeState)
        return CGSize(width: 300, height: z.height)
    }
    public override var isFlipped: Bool { true }
    public override func draw(_ dirtyRect: NSRect) {
        let cgctx = NSGraphicsContext.current!.cgContext
        let rendering = CodeRendering(
            config: editing.config,
            storage: editing.storage,
            imeState: editing.imeState,
            annotation: annotation,
            bounds: bounds,
            scale: window?.backingScaleFactor ?? 1)
        rendering.draw(
            in: dirtyRect,
            with: cgctx)
    }
}
