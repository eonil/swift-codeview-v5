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
        case let .editing(ed):
            codeSource = ed.sourceAfterReplacement
            print("ver: \(codeSource.version), lines: \(codeSource.storage.lines.count)")
            print(ed.sourceBeforeReplacement.lineContentsInCurrentSelection())
            print(ed.replacementContent)
        case let .replaceAllSilently(s):
            print("ver: \(s.version), lines: \(s.storage.lines.count)")
            codeSource = s
        case .cancelOperation:
            print("cancel!")
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
        scrollCodeView.codeView.control.send(.reset(codeSource))
    }
    @IBAction
    public func testTextEditing(_:AnyObject) {
        codeSource.replaceCharactersInCurrentSelection(with: "\nPerforms an editing...")
        scrollCodeView.codeView.control.send(.edit(codeSource, nameForMenu: "Test"))
    }

    ///

    private func install() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        scrollCodeView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollCodeView)
        NSLayoutConstraint.activate([
            scrollCodeView.leftAnchor.constraint(equalTo: leftAnchor),
            scrollCodeView.rightAnchor.constraint(equalTo: rightAnchor),
            scrollCodeView.topAnchor.constraint(equalTo: topAnchor),
            scrollCodeView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        scrollCodeView.codeView.note.sink(receiveValue: { [weak self] in self?.process($0) }).store(in: &pipes)
    }
}
