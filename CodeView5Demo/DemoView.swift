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
    private var codeManagement = CodeManagement()
//    private let completionWindowManagement = CompletionWindowManagement()
    
    private func process(_ m:CodeView.Note) {
        codeManagement.process(.userInteraction(m))
        codeManagement.send(to: scrollCodeView.codeView)
        
        //
        let src = codeManagement.editing.source
//        print("ver: \(src.version)")
        for p in src.timeline.points {
            let oldContent = p.baseSnapshot.lineContents(in: p.replacementRange).joined(separator: "\n")
            let newContent = p.replacementContent
            print("#\(p.key): `\(oldContent)` -> `\(newContent)`")
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
    deinit {
        
    }

    public override var acceptsFirstResponder: Bool { return true }
    public override func becomeFirstResponder() -> Bool {
        return window?.makeFirstResponder(scrollCodeView) ?? false
    }
    @IBAction
    public func testTextReloading(_:AnyObject?) {
        codeManagement.process(.userInteraction(.edit(.reset(CodeSource()))))
        codeManagement.send(to: scrollCodeView.codeView)
        codeManagement.process(.userInteraction(.edit(.typing(.placeText("Resets to a new document.")))))
        codeManagement.send(to: scrollCodeView.codeView)
    }
    @IBAction
    public func testTextEditing(_:AnyObject?) {
        var src = codeManagement.editing.source
        src.replaceCharactersInCurrentSelection(with: "\nPerforms an editing...")
        codeManagement.process(.userInteraction(.edit(.edit(src, nameForMenu: "Test"))))
        codeManagement.send(to: scrollCodeView.codeView)
    }
    @IBAction
    public func testClosingWindow(_:AnyObject?) {
        window?.close()
    }

    // MARK: -
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
//        scrollCodeView.codeView.completionWindow = demoCompletionWindow
//        scrollCodeView.codeView.note = { [weak self] n in
//            DispatchQueue.main.async { [weak self] in
//                RunLoop.main.perform { [weak self] in
//                    self?.process(n)
//                }
//            }
//        }
        scrollCodeView.codeView.note = { [weak self] n in self?.process(n) }
        scrollCodeView.codeView.completionView = NSButton()
    }
}
