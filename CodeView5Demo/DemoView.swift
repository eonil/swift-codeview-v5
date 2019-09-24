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
        // Pre-process accumulated effect cleansing.
        codeManagement.clean()
        // Process message and produce result.
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
            var anno = CodeAnnotation()
            for _ in 0..<40 {
                if let lineOffset = lineOffsets.randomElement() {
                    anno.breakPoints.insert(lineOffset)
                }
            }
            for _ in 0..<40 {
                if let lineOffset = lineOffsets.randomElement() {
                    let sevs = [.info, .warn, .error] as [CodeLineAnnotation.Diagnostic.Severity]
                    let s = sevs.randomElement() ?? .error
                    switch s {
                    case .info:
                        anno.lineAnnotations[lineOffset] = CodeLineAnnotation(
                            diagnostics: [.init(message: "Informative note.", severity: .info)])
                    case .warn:
                        anno.lineAnnotations[lineOffset] = CodeLineAnnotation(
                            diagnostics: [.init(message: "Warning.", severity: .warn)])
                    case .error:
                        anno.lineAnnotations[lineOffset] = CodeLineAnnotation(
                            diagnostics: [.init(message: "Error.", severity: .error)])
                    }
                    
                }
            }
            codeManagement.process(.setAnnotation(anno))
        }
        // Post-process auto-completion.
        if let p = codeManagement.editing.storage.timeline.points.last {
            let config = codeManagement.editing.config
            switch p.replacementContent {
            case "\n":
                // Indent only.
                var s = codeManagement.editing.storage
                let upLineContent = s.text.lines.atOffset(s.caretPosition.lineOffset-1).content
                let lv = upLineContent.countPrefix(" ") / config.editing.tabSpaceCount
                let a = String(repeating: " ", count: lv * config.editing.tabSpaceCount)
                s.replaceCharactersInCurrentSelection(with: a)
                codeManagement.process(.userInteraction(.edit(.edit(s, nameForMenu: "Completion"))))
            case "{":
                // Closing with indent.
                var s = codeManagement.editing.storage
                let lineContent = s.text.lines.atOffset(s.caretPosition.lineOffset).content
                let lv = lineContent.countPrefix(" ") / config.editing.tabSpaceCount
                let a = String(repeating: " ", count: lv * config.editing.tabSpaceCount)
                let b = String(repeating: " ", count: lv.advanced(by: 1) * config.editing.tabSpaceCount)
                s.replaceCharactersInCurrentSelection(with: "\n\(b)")
                let p = s.caretPosition
                s.replaceCharactersInCurrentSelection(with: "\n\(a)}")
                s.moveCaret(to: p)
                codeManagement.process(.userInteraction(.edit(.edit(s, nameForMenu: "Completion"))))
            default:
                break
            }
        }
        // Render.
        render()
    }
    private func render() {
        // Render.
        codeManagement.send(to: scrollCodeView.codeView)
        // Scroll to editing point if any editing happened.
        let p = codeManagement.editing.storage.caretPosition
        scrollCodeView.showLineAtOffset(p.lineOffset, in: codeManagement.editing)
        
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

private extension CodeStorage {
    func countIndentationLevelAtCaretLine(with x:CodeConfig) -> Int {
        let lineContent = text.lines.atOffset(caretPosition.lineOffset).content
        let prefixSpaceCount = lineContent.countPrefix(" ")
        let indentationLevel = prefixSpaceCount / x.editing.tabSpaceCount
        return indentationLevel
    }
}
private extension Substring {
    func countPrefix(_ ch:Character) -> Int {
        var c = 0
        for ch1 in self {
            if ch1 == ch { c += 1 }
            else { break }
        }
        return c
    }
    func countPrefix(_ s:String) -> Int {
        let chc = s.count
        var c = 0
        var ss = self[startIndex...]
        while ss.hasPrefix(s) {
            ss = ss.dropFirst(chc)
            c += 1
        }
        return c
    }
}

