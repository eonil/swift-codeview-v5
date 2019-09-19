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

final class DemoView: NSView, NSUserInterfaceValidations {
    private let scrollCodeView = ScrollCodeView()
    private var codeSource = CodeSource()
    
    private func process(_ n:CodeView.Note) {
        switch n {
        case let .editing(src):
            print("ver: \(src.version)")
            for p in src.timeline.points {
                let oldContent = p.baseSnapshot.lineContents(in: p.replacementRange).joined(separator: "\n")
                let newContent = p.replacementContent
                print("#\(p.key): `\(oldContent)` -> `\(newContent)`")
            }
            codeSource = src
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
        scrollCodeView.codeView.control(.reset(codeSource))
    }
    @IBAction
    public func testTextEditing(_:AnyObject) {
        codeSource.replaceCharactersInCurrentSelection(with: "\nPerforms an editing...")
        scrollCodeView.codeView.control(.edit(codeSource, nameForMenu: "Test"))
    }
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        return scrollCodeView.codeView.isSynchronized
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
        scrollCodeView.codeView.note = { [weak self] n in
            DispatchQueue.main.async { [weak self] in
                RunLoop.main.perform { [weak self] in
                    self?.process(n)
                }
            }
        }
    }
}
