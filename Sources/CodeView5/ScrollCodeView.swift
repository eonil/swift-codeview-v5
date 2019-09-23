//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/6/19.
//

import Foundation
import AppKit

/// Conveniently constructed code editing view.
///
/// This view embeds a scroll-view, a code-view in it and completion window managemnet.
/// This is convenient class to provide properly configured prebuilt scrolling and completion window management.
///
/// - Note:
///     This view yields first-responder state to internal code-view.
///     Though internal code-view is exposed to public, please do not control
///     its layout yourself to keep it correct.
///
public final class ScrollCodeView: NSView {
    private let scrollView = NSScrollView()
    /// Exposed to public for convenience.
    /// Use this view to convert points/frames from/to other views.
    public let codeView = CodeView()
    public override init(frame f: NSRect) {
        super.init(frame: f)
        install()
    }
    public required init?(coder c: NSCoder) {
        super.init(coder: c)
        install()
    }
    public override var acceptsFirstResponder: Bool { return true }
    public override func becomeFirstResponder() -> Bool {
        return window?.makeFirstResponder(codeView) ?? false
    }
    private func install() {
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leftAnchor.constraint(equalTo: leftAnchor),
            scrollView.rightAnchor.constraint(equalTo: rightAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        scrollView.documentView = codeView
        codeView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            codeView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            codeView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            codeView.widthAnchor.constraint(greaterThanOrEqualTo: scrollView.widthAnchor),
            codeView.bottomAnchor.constraint(greaterThanOrEqualTo: scrollView.bottomAnchor),
        ])
    }
}
