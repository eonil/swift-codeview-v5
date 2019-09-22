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
    private var editing = CodeEditing()
    /// - Note:
    ///     You have to use only valid line offsets.
    /// - TODO: Optimize this.
    /// Need to be optimized.
    /// This would be okay for a while as most people do not install
    /// too many break-points. But if there are more than 100 break-points,
    /// this is very likely to make problems.
    public private(set) var breakpointLineOffsets = Set<Int>()
    private var completionWindowState = CompletionWindowState()
    /// Visibility and range is separated as visibility can be changed by completion content
    /// and completion content can be different at range.
    public struct CompletionWindowState {
        /// User's intention whether to see the completion window or not.
        public var wantsVisible = false
        /// We cannot keep invalid range if detected.
        /// In that case, this gonna be `nil`.
        public var aroundRange = Range<CodeStoragePosition>?.none
        /// Finally aggregated visibility.
        public var isVisible: Bool {
            return wantsVisible && aroundRange != nil
        }
    }

    // MARK: - External I/O
    /// A view to be contained in completion window if the window becomes visible.
    @IBOutlet
    public var completionView: NSView? {
        get { completionWindowManagement.completionView }
        set(x) { completionWindowManagement.completionView = x }
    }
    public enum Control {
        /// Apply effects on client side.
        case applyEffect(Effect)
        public enum Effect {
            case replacePasteboardContent(String)
        }
        /// Render editing state on client side.
        case renderEditing(CodeEditing)
        case renderBreakPointLineOffsets(Set<Int>)
        /// Render completion window state.
        /// Defines whow completion window to be rendered.
        /// `nil` means completion window should be disappeared.
        /// - Note:
        ///     Default text processing engine `CodeEditing`
        ///     doesn't deal with completion window at all.
        ///     You need to deal with them yourself if you want.
        ///     Or you can use `CodeView2Management`
        ///     that also deals with completion window.
        case renderCompletionWindow(CompletionWindowState)
    }
    /// Sends control message.
    public func control(_ m:Control) {
        process(m)
    }
    public var note: ((Note) -> Void)?
    public typealias Note = CodeUserMessage
    
    // MARK: - Initialization
    private func install() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        typing.note = { [weak self] n in self?.note?(.edit(.typing(n))); () }
        completionWindowManagement.codeView = self
    }
    
    // MARK: -
    private func process(_ m:Control) {
        switch m {
        case let .applyEffect(effect):
            switch effect {
            case let .replacePasteboardContent(s):
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(s, forType: .string)
            }
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
                // Scroll current line to be visible.
                let layout = CodeLayout(
                    config: editing.config,
                    source: editing.storage,
                    imeState: editing.imeState,
                    boundingWidth: bounds.width)
                let f = layout.frameOfLine(
                    at: editing.storage.caretPosition.lineOffset)
                scrollToVisible(f)
                switch editing.invalidatedRegion {
                case .none:                 break
                case let .some(subbounds):  setNeedsDisplay(subbounds)
                case .all:                  setNeedsDisplay(bounds)
                }
            }
            
        case let .renderBreakPointLineOffsets(mm):
            breakpointLineOffsets = mm
            let f = CGRect(
                x: 0,
                y: 0,
                width: editing.config.rendering.breakpointWidth,
                height: bounds.height)
            setNeedsDisplay(f)
            
        case let .renderCompletionWindow(mm):
            completionWindowState = mm
            typealias CWS = CompletionWindowManagement.State
            let cs = mm.aroundRange == nil ? CWS?.none : CWS(
                config: editing.config,
                source: editing.storage,
                imeState: editing.imeState,
                completionRange: mm.aroundRange!)
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
    public override func resize(withOldSuperviewSize oldSize: NSSize) {
        super.resize(withOldSuperviewSize: oldSize)
        note?(.view(.resize))
    }
    public override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        note?(.view(.resize))
    }
    public override func viewWillStartLiveResize() {
        super.viewWillStartLiveResize()
        note?(.view(.resize))
    }
    public override func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()
        note?(.view(.resize))
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
        default:
            return true
        }
    }
    public override var intrinsicContentSize: NSSize {
        let layout = CodeLayout(
            config: editing.config,
            source: editing.storage,
            imeState: editing.imeState,
            boundingWidth: bounds.width)
        let z = layout.measureContentSize(
            source: editing.storage,
            imeState: editing.imeState)
        return CGSize(width: 300, height: z.height)
    }
    public override var isFlipped: Bool { true }
    public override func draw(_ dirtyRect: NSRect) {
        let cgctx = NSGraphicsContext.current!.cgContext
        let rendering = CodeRendering(
            config: editing.config,
            breakpointLineOffsets: breakpointLineOffsets)
        rendering.draw(
            source: editing.storage,
            imeState: editing.imeState,
            in: dirtyRect,
            with: cgctx)
    }
}
