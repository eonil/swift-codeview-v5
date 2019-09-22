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
    
    private func process(_ m:CodeView.Note) {
        codeManagement.process(.userInteraction(m))
        codeManagement.send(to: scrollCodeView.codeView)
        
        let c = codeManagement.editing.storage.bestEffortCursorAtCaret
        if c.inLineCharCursor.priorChar == "." {
            scrollCodeView.codeView.control(.renderCompletionWindow(around: c.position..<c.position))
            codeManagement.send(to: scrollCodeView.codeView)
        }
        
        //
        print("editing storage ver: \(codeManagement.editing.timeline.currentPoint.version)")
        print("storage changeset count: \(codeManagement.editing.storage.timeline.points.count)")
        let src = codeManagement.editing.storage
        for p in src.timeline.points {
            let oldContent = p.baseSnapshot.lineContents(in: p.replacementRange).joined(separator: "\n")
            let newContent = p.replacementContent
            print("`\(oldContent)` -> `\(newContent)`")
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
        codeManagement.process(.userInteraction(.edit(.reset(CodeStorage()))))
        codeManagement.send(to: scrollCodeView.codeView)
        codeManagement.process(.userInteraction(.edit(.typing(.placeText("Resets to a new document.")))))
        codeManagement.send(to: scrollCodeView.codeView)
        print("editing storage ver: \(codeManagement.editing.timeline.currentPoint.version)")
        print("storage changeset count: \(codeManagement.editing.storage.timeline.points.count)")
    }
    @IBAction
    public func testTextEditing(_:AnyObject?) {
        var src = codeManagement.editing.storage
        src.replaceCharactersInCurrentSelection(with: "\nPerforms an editing...")
        codeManagement.process(.userInteraction(.edit(.edit(src, nameForMenu: "Test"))))
        codeManagement.send(to: scrollCodeView.codeView)
        print("editing storage ver: \(codeManagement.editing.timeline.currentPoint.version)")
        print("storage changeset count: \(codeManagement.editing.storage.timeline.points.count)")
    }
    @IBAction
    public func testBreakpointSetting(_:AnyObject?) {
        let lineOffsets = codeManagement.editing.storage.text.lines.offsets
        var breakPoints = codeManagement.breakPointLineOffsets
        if let lineOffset = lineOffsets.randomElement() {
            breakPoints.insert(lineOffset)
        }
        codeManagement.process(.setBreakPointLineOffsets(breakPoints))
        codeManagement.send(to: scrollCodeView.codeView)
        print("editing storage ver: \(codeManagement.editing.timeline.currentPoint.version)")
        print("storage changeset count: \(codeManagement.editing.storage.timeline.points.count)")
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
        print("editing storage ver: \(codeManagement.editing.timeline.currentPoint.version)")
        print("storage changeset count: \(codeManagement.editing.storage.timeline.points.count)")
    }
    @IBAction
    func redo(_:AnyObject?) {
        codeManagement.process(.userInteraction(.menu(.redo)))
        codeManagement.send(to: scrollCodeView.codeView)
        print("editing storage ver: \(codeManagement.editing.timeline.currentPoint.version)")
        print("storage changeset count: \(codeManagement.editing.storage.timeline.points.count)")
    }
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        switch item.action {
        case #selector(undo(_:)):   return codeManagement.editing.timeline.canUndo
        case #selector(redo(_:)):   return codeManagement.editing.timeline.canRedo
        default:                    return true
        }
    }
}
