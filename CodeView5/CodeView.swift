//
//  CodeView.swift
//  CodeView5
//
//  Created by Henry on 2019/07/25.
//  Copyright © 2019 Eonil. All rights reserved.
//

import Foundation
import AppKit

public final class CodeView: NSView {
    private let implTIC = IMPLTextInputClientView()

    public enum Control {
        case setSourceURL(URL?)
        /// Pushes modified source.
//        case setSource(CodeSource)
    }


    ///

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
        return window?.makeFirstResponder(implTIC) ?? false
    }

    ///

    private func install() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.red.cgColor
        implTIC.translatesAutoresizingMaskIntoConstraints = false
        addSubview(implTIC)
        NSLayoutConstraint.activate([
            implTIC.leftAnchor.constraint(equalTo: leftAnchor),
            implTIC.rightAnchor.constraint(equalTo: rightAnchor),
            implTIC.topAnchor.constraint(equalTo: topAnchor),
            implTIC.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        implTIC.note = { [weak self] n in self?.process(n) }
    }
    private func process(_ n: IMPLTextInputControl) {
        print(n)
//        switch n {
//        case .characters(let s):
//        case .setCharacterInComposition(let s):
//        }
    }
}
