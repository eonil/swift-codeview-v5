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
    private var codeManagement = CodeManagement()
//    private let completionWindowManagement = CompletionWindowManagement()
    
    private func process(_ m:CodeView.Note) {
        codeManagement.process(.userInteraction(m))
        codeManagement.send(to: scrollCodeView.codeView)
        
        //
        print("editing ver: \(codeManagement.editing.timeline.currentPoint.version)")
        print("storage ver: \(codeManagement.editing.source.timeline.points.last?.key.description ?? "")")
        let src = codeManagement.editing.source
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
        print("editing ver: \(codeManagement.editing.timeline.currentPoint.version)")
        print("storage ver: \(codeManagement.editing.source.timeline.points.last?.key.description ?? "")")
    }
    @IBAction
    public func testTextEditing(_:AnyObject?) {
        var src = codeManagement.editing.source
        src.replaceCharactersInCurrentSelection(with: "\nPerforms an editing...")
        codeManagement.process(.userInteraction(.edit(.edit(src, nameForMenu: "Test"))))
        codeManagement.send(to: scrollCodeView.codeView)
        print("editing ver: \(codeManagement.editing.timeline.currentPoint.version)")
        print("storage ver: \(codeManagement.editing.source.timeline.points.last?.key.description ?? "")")
    }
    @IBAction
    public func testBreakpointSetting(_:AnyObject?) {
        let lineOffsets = codeManagement.editing.source.storage.lines.offsets
        var breakPoints = codeManagement.breakPointLineOffsets
        if let lineOffset = lineOffsets.randomElement() {
            breakPoints.insert(lineOffset)
        }
        codeManagement.process(.setBreakPointLineOffsets(breakPoints))
        codeManagement.send(to: scrollCodeView.codeView)
        print("editing ver: \(codeManagement.editing.timeline.currentPoint.version)")
        print("storage ver: \(codeManagement.editing.source.timeline.points.last?.key.description ?? "")")
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
        scrollCodeView.codeView.note = { [weak self] n in self?.process(n) }
        scrollCodeView.codeView.completionView = NSButton()
    }
    
    @IBAction
    func undo(_:AnyObject?) {
        codeManagement.process(.userInteraction(.menu(.undo)))
        codeManagement.send(to: scrollCodeView.codeView)
        print("editing ver: \(codeManagement.editing.timeline.currentPoint.version)")
        print("storage ver: \(codeManagement.editing.source.timeline.points.last?.key.description ?? "")")
    }
    @IBAction
    func redo(_:AnyObject?) {
        codeManagement.process(.userInteraction(.menu(.redo)))
        codeManagement.send(to: scrollCodeView.codeView)
        print("editing ver: \(codeManagement.editing.timeline.currentPoint.version)")
        print("storage ver: \(codeManagement.editing.source.timeline.points.last?.key.description ?? "")")
    }
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        switch item.action {
        case #selector(undo(_:)):   return codeManagement.editing.timeline.canUndo
        case #selector(redo(_:)):   return codeManagement.editing.timeline.canRedo
        default:                    return true
        }
    }
}
