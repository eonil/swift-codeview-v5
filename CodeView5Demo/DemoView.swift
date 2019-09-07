//
//  DemoView.swift
//  CodeView5Demo
//
//  Created by Henry on 2019/07/25.
//  Copyright © 2019 Eonil. All rights reserved.
//

import Foundation
import Combine
import AppKit
import CodeView5

final class DemoView: NSView {
    private let scrollCodeView = ScrollCodeView()
    private var pipes = [AnyCancellable]()
//    private let codeView = CodeView()
    private var codeSource = CodeSource()
    
    private func process(_ n:CodeView.Note) {
        switch n {
        case let .source(s):
            codeSource = s
        }
    }

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
    @IBAction
    public func testTextReloading(_:AnyObject) {
        codeSource = CodeSource()
        codeSource.replaceCharactersInCurrentSelection(with: "Resets to a new document.")
        scrollCodeView.control.send(.reset(codeSource))
    }
    @IBAction
    public func testTextEditing(_:AnyObject) {
        codeSource.replaceCharactersInCurrentSelection(with: "\nPerforms an editing...")
        scrollCodeView.control.send(.edit(codeSource, nameForMenu: "Test"))
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
        scrollCodeView.note.sink(receiveValue: { [weak self] in self?.process($0) }).store(in: &pipes)
    }
}
