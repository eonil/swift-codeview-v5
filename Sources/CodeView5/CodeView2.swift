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
/// Asynchronicity Friendly
/// -----------------------
/// Input scanning and output rendering doesn't have to be synchronous.
/// Remeber that this view is just simple grouping of two different views; (1) input scanner, (2) output renderer.
/// User can issue any command for whatever editing state. It's code editing engine's responsibility
/// how to deal with them.
/// Anyway, if rendering gets delayed a lot, user can make wrong decision on editing command.
/// Therefore, editing engine should call rendering control ASAP. Typically, more than 10ms latency
/// is considered too slow.
///
@IBDesignable
public final class CodeView2: NSView {
    private let completionWindowManagement = CompletionWindowManagement()
    private let typing = TextTyping()
    private var snapshot = CodeView2Management.State()

    // MARK: - External I/O
    @IBOutlet
    public var completionView: NSView? {
        get { completionWindowManagement.completionView }
        set(x) { completionWindowManagement.completionView = x }
    }
    /// Sends control message.
    public func control(_ c:CodeEditingStateRenderingMessage) {
        switch c {
        case let .applyEffect(effect):
            switch effect {
            case let .replacePasteboardContent(s):
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(s, forType: .string)
            }
        case let .stateSnapshot(s):
            snapshot = s
            do {
                let f = s.state.typingFrame(config: s.config, in: bounds)
                let f1 = convert(f, to: nil)
                let f2 = window?.convertToScreen(f1) ?? .zero
                typing.control(.setTypingFrame(f2))
            }
            do {
                // Force to resize for new source state.
                invalidateIntrinsicContentSize()
                layoutSubtreeIfNeeded()
                // Scroll current line to be visible.
                let layout = CodeLayout(
                    config: s.config,
                    source: s.state.source,
                    imeState: s.state.imeState,
                    boundingWidth: bounds.width)
                let f = layout.frameOfLine(
                    at: s.state.source.caretPosition.lineOffset)
                scrollToVisible(f)
                switch s.invalidatedRegion {
                case .none:                 break
                case let .some(subbounds):  setNeedsDisplay(subbounds)
                case .all:                  setNeedsDisplay(bounds)
                }
                display()
            }
            
            //
            typealias CWS = CompletionWindowManagement.State
            let r = snapshot.completionWindowState?.aroundRange
            let cs = r == nil ? CWS?.none : CWS(
                config: snapshot.config,
                source: snapshot.state.source,
                imeState: snapshot.state.imeState,
                completionRange: r!)
            completionWindowManagement.setState(cs)
        }
    }
    public typealias Control = CodeEditingStateRenderingMessage
    public var note: ((Note) -> Void)?
    public typealias Note = CodeUserInteractionScanningMessage
    
    // MARK: - Initialization
    private func install() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        typing.note = { [weak self] n in self?.note?(.edit(.typing(n))); () }
        completionWindowManagement.codeView = self
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
        defer {
            typing.activate()
            note?(.view(.becomeFirstResponder))
        }
        return super.becomeFirstResponder()
    }
    public override func resignFirstResponder() -> Bool {
        typing.deactivate()
        defer {
            note?(.view(.resignFirstResponder))
        }
        return super.resignFirstResponder()
    }
    public override var canBecomeKeyView: Bool { true }
    public override func keyDown(with event: NSEvent) {
        typing.processEvent(event)
    }
    public override func mouseDown(with event: NSEvent) {
        typing.processEvent(event)
        let pw = event.locationInWindow
        let pv = convert(pw, from: nil)
        let mm = CodeEditing.Message.MouseMessage(
            kind: .down,
            pointInBounds: pv,
            bounds: bounds)
        note?(.edit(.mouse(mm)))
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
        note?(.edit(.mouse(mm)))
    }
    public override func mouseUp(with event: NSEvent) {
        typing.processEvent(event)
        let pw = event.locationInWindow
        let pv = convert(pw, from: nil)
        let mm = CodeEditing.Message.MouseMessage(
            kind: .up,
            pointInBounds: pv,
            bounds: bounds)
        note?(.edit(.mouse(mm)))
    }
    public override func selectAll(_ sender: Any?) {
        note?(.menu(.selectAll))
    }
    @IBAction
    func copy(_:AnyObject) {
        note?(.menu(.copy))
    }
    @IBAction
    func cut(_:AnyObject) {
        note?(.menu(.cut))
    }
    @IBAction
    func paste(_:AnyObject) {
        guard let s = NSPasteboard.general.string(forType: .string) else { return }
        note?(.menu(.paste(s)))
    }
    @IBAction
    func undo(_:AnyObject) {
        note?(.menu(.undo))
    }
    @IBAction
    func redo(_:AnyObject) {
        note?(.menu(.redo))
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
            return true
        case #selector(cut(_:)):
            return true
        case #selector(paste(_:)):
            return true
        case #selector(undo(_:)):
            return snapshot.state.timeline.canUndo
        case #selector(redo(_:)):
            return snapshot.state.timeline.canRedo
        default:
            return true
        }
    }
    public override var intrinsicContentSize: NSSize {
        let layout = CodeLayout(
            config: snapshot.config,
            source: snapshot.state.source,
            imeState: snapshot.state.imeState,
            boundingWidth: bounds.width)
        let z = layout.measureContentSize(
            source: snapshot.state.source,
            imeState: snapshot.state.imeState)
        return CGSize(width: 300, height: z.height)
    }
    public override var isFlipped: Bool { true }
    public override func draw(_ dirtyRect: NSRect) {
        let cgctx = NSGraphicsContext.current!.cgContext
        var render = CodeRendering()
        render.config = snapshot.config
        render.draw(
            source: snapshot.state.source,
            imeState: snapshot.state.imeState,
            in: dirtyRect,
            with: cgctx)
    }
}
