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
    enum Message {
        case user(CodeUserMessage)
        case undo
        case redo
        case testTextReloading
        case testTextEditing
        case testBreakpointResetting
    }
    
    private let scrollCodeView = ScrollCodeView()
    private var codeManagement = CodeManagement()
    
    private func process(_ m:Message) {
        codeManagement.clean()
        switch m {
        case let .user(mm):
            codeManagement.process(.userInteraction(mm))
        case .undo:
            codeManagement.process(.userInteraction(.menu(.undo)))
        case .redo:
            codeManagement.process(.userInteraction(.menu(.redo)))
        case .testTextReloading:
            codeManagement.process(.userInteraction(.edit(.reset(CodeStorage()))))
            codeManagement.process(.userInteraction(.edit(.typing(.placeText("Resets to a new document.")))))
        case .testTextEditing:
            var src = codeManagement.editing.storage
            src.replaceCharactersInCurrentSelection(with: "\nPerforms an editing...")
            codeManagement.process(.userInteraction(.edit(.edit(src, nameForMenu: "Test"))))
        case .testBreakpointResetting:
            let lineOffsets = codeManagement.editing.storage.text.lines.offsets
            var breakPoints = codeManagement.breakPointLineOffsets
            if let lineOffset = lineOffsets.randomElement() {
                breakPoints.insert(lineOffset)
            }
            codeManagement.process(.setBreakPointLineOffsets(breakPoints))
        }
        print("editing storage ver: \(codeManagement.editing.timeline.currentPoint.version)")
        print("storage changeset count: \(codeManagement.editing.storage.timeline.points.count)")
        
        // Post-processing.
        if let p = codeManagement.editing.storage.timeline.points.last {
            // Auto-indent.
            let config = codeManagement.editing.config
            if p.replacementContent == "\n" && config.editing.autoIndent {
                var s = codeManagement.editing.storage
                let upLineOffset = s.caretPosition.lineOffset-1
                let upLineIndex = s.text.lines.startIndex + upLineOffset
                let upLine = s.text.lines[upLineIndex]
                let tabReplacement = config.editing.makeTabReplacement()
                let n = upLine.countPrefix(tabReplacement)
                for _ in 0..<n {
                    s.replaceCharactersInCurrentSelection(with: tabReplacement)
                }
                codeManagement.process(.userInteraction(.edit(.edit(s, nameForMenu: "Completion"))))
            }
            // Auto-closing.
            if p.replacementRange.isEmpty && p.replacementContent == "{" {
                var s = codeManagement.editing.storage
                s.replaceCharactersInCurrentSelection(with: "\n    \n}")
                var c = s.bestEffortCursorAtCaret
                c.moveOneCharToStart()
                c.moveOneCharToStart()
                s.caretPosition = c.position
                s.selectionRange = c.position..<c.position
                s.selectionAnchorPosition = nil
                codeManagement.process(.userInteraction(.edit(.edit(s, nameForMenu: "Completion"))))
            }
        }
        render()
    }
    private func render() {
        // Render.
        codeManagement.send(to: scrollCodeView.codeView)
        
        // Render completion window.
        let c = codeManagement.editing.storage.bestEffortCursorAtCaret
        if c.inLineCharCursor.priorChar == "." {
            scrollCodeView.codeView.control(.renderCompletionWindow(around: c.position..<c.position))
        }
        
        // Render stats.
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
        process(.testTextReloading)
    }
    @IBAction
    public func testTextEditing(_:AnyObject?) {
        process(.testTextEditing)
    }
    @IBAction
    public func testBreakpointSetting(_:AnyObject?) {
        process(.testBreakpointResetting)
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
        scrollCodeView.codeView.note = { [weak self] m in self?.process(.user(m)) }
        scrollCodeView.codeView.completionView = NSButton()
    }
    
    @IBAction
    func undo(_:AnyObject?) {
        process(.undo)
    }
    @IBAction
    func redo(_:AnyObject?) {
        process(.redo)
    }
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        switch item.action {
        case #selector(undo(_:)):   return codeManagement.editing.timeline.canUndo
        case #selector(redo(_:)):   return codeManagement.editing.timeline.canRedo
        default:                    return true
        }
    }
}

extension CodeLine {
    func countPrefix(_ ch:Character) -> Int {
        var c = 0
        for ch1 in content {
            if ch1 == ch { c += 1 }
            else { break }
        }
        return c
    }
    func countPrefix(_ s:String) -> Int {
        let chc = s.count
        var c = 0
        var ss = content[content.startIndex...]
        while ss.hasPrefix(s) {
            ss = ss.dropFirst(chc)
            c += 1
        }
        return c
    }
}

