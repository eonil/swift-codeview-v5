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
    private let impl = CodeView()

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
        return window?.makeFirstResponder(impl) ?? false
    }

    ///

    private func install() {
        impl.translatesAutoresizingMaskIntoConstraints = false
        addSubview(impl)
        NSLayoutConstraint.activate([
            impl.leftAnchor.constraint(equalTo: leftAnchor),
            impl.rightAnchor.constraint(equalTo: rightAnchor),
            impl.topAnchor.constraint(equalTo: topAnchor),
            impl.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
