//
//  DemoView.swift
//  CodeView5Demo
//
//  Created by Henry on 2019/07/25.
//  Copyright © 2019 Eonil. All rights reserved.
//

import Foundation
import AppKit
import CodeView5

final class DemoView: NSView {
    private let scrollCodeView = ScrollCodeView()
//    private let codeView = CodeView()

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
        return window?.makeFirstResponder(scrollCodeView) ?? false
    }

    ///

    private func install() {
        scrollCodeView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollCodeView)
        NSLayoutConstraint.activate([
            scrollCodeView.leftAnchor.constraint(equalTo: leftAnchor),
            scrollCodeView.rightAnchor.constraint(equalTo: rightAnchor),
            scrollCodeView.topAnchor.constraint(equalTo: topAnchor),
            scrollCodeView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
//        scrollView.documentView = codeView
//        codeView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            codeView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
//            codeView.widthAnchor.constraint(greaterThanOrEqualTo: scrollView.widthAnchor),
//        ])
    }
}
