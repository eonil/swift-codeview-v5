//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/20/19.
//

import Foundation
import AppKit

/// - Set `codeView`.
/// - Set `completionView`.
/// - Call `setState(...)`.
/// - Call `invalidate()` when `codeView`'s first responder state changes.
public final class CompletionWindowManagement {
    public weak var codeView: NSView? { didSet { render() } }
    private let completionWindow = CompletionWindow()
    public private(set) var state = State?.none
    public var windowSize = CGSize(width: 300, height: 200)
    
    public struct State {
        public let config: CodeConfig
        public let source: CodeStorage
        public let imeState: IMEState?
        /// Sets completion range.
        /// If this is a non-nil value, a completion window will be shown
        /// with `completionView` around the range.
        public let completionRange: Range<CodeStoragePosition>
        /// You haeve to supplied them all at once as all parameters must be consistent.
        public init(
            config a: CodeConfig,
            source b: CodeStorage,
            imeState c: IMEState?,
            completionRange d: Range<CodeStoragePosition>) {
                config = a
                source = b
                imeState = c
                completionRange = d
        }
    }
    
    // MARK: -
    public init() {
        // Workaround to avoid potential exception of close.
        // https://stackoverflow.com/a/58038216/246776
        completionWindow.orderFront(nil)
        completionWindow.orderOut(nil)
    }
    deinit {
        completionWindow.setIsVisible(false)
    }
    /// View to be displayed in completion window.
    /// You can set a view here to provide your own completion UI.
    /// and `CodeView` will manage its position and visibility.
    /// This manager owns the assigned view.
    public var completionView: NSView? {
        get { completionWindow.contentView }
        set(x) { completionWindow.contentView = x; render() }
    }
    public func setState(_ s:State?) {
        state = s
        render()
    }
    public func invalidate() {
        render()
    }
    private func render() {
        setCompletionWindowPosition()
    }
}

private extension CompletionWindowManagement {
    func setCompletionWindowPosition() {
        let f = completionWindowFrameInScreen
        let isVisible = state?.completionRange != nil && f != nil && codeView?.window?.firstResponder === codeView
        completionWindow.orderFront(self)
        completionWindow.setIsVisible(isVisible)
        completionWindow.setFrame(f ?? CGRect(origin: .zero, size: windowSize), display: isVisible)
        completionWindow.styleMask.formUnion([.unifiedTitleAndToolbar, .fullSizeContentView])
        completionWindow.titleVisibility = .hidden
        completionWindow.titlebarAppearsTransparent = true
        completionWindow.level = .floating
        completionWindow.isReleasedWhenClosed = false
    }
    var completionWindowFrameInScreen: CGRect? {
        guard let state = state else { return nil }
        guard let codeViewBoundsWidth = codeView?.bounds.width else { return nil }
        let range = state.completionRange
        let layout = state.source.makeLayout(config: state.config, imeState: state.imeState, boundingWidth: codeViewBoundsWidth)
        
        let bottomLineOffset = range.upperBound.lineOffset
        let bottomCharOffsetRange = range.characterUTF8OffsetRangeOfLine(at: bottomLineOffset, in: state.source.text)
        let bottomSelFrame = layout.frameOfTextUTF8OffsetSubrange(bottomCharOffsetRange, inLineAt: bottomLineOffset)
        
        let frameInCodeView = bottomSelFrame
        guard let frameInWindow = codeView?.convert(frameInCodeView, to: nil) else { return nil }
        guard let frameInScreen = codeView?.window?.convertToScreen(frameInWindow) else { return nil }
        let completionFrameInScreen = CGRect(
            x: frameInScreen.minX,
            y: frameInScreen.minY - windowSize.height,
            width: windowSize.width,
            height: windowSize.height)
        return completionFrameInScreen
    }
}
