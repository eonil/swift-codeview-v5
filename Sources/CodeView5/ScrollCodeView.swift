//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/6/19.
//

import Foundation
import Combine
import AppKit

/// A code-view embeded in a scroll-view.
/// This is convenient class to provide properly configured prebuilt scrolling.
/// - Note:
///     This view yields first-responder state to internal code-view.
///     You cannot access internal code-view directly.
///     But you can I/O with internal code-view using its `Control` and `Note`.
public final class ScrollCodeView: NSView {
    private let scrollView = NSScrollView()
    private let codeView = CodeView()
    
    public var control: PassthroughSubject<CodeView.Control,Never> { codeView.control }
    public var note: PassthroughSubject<CodeView.Note,Never> { codeView.note }
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
