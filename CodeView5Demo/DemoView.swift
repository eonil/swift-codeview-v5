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
        case user(CodeEditingMessage)
        case undo
        case redo
        case copy
        case cut
        case paste
        case selectAll
        case testTextReloading
        case testTextEditing
        case testBreakpointResetting
        case testToggleVisibility
    }
    
    private let scrollCodeView = ScrollCodeView()
    private var codeManagement = CodeManagement()
    
    private func process(_ m:Message) {
        // Pre-process accumulated effect cleansing.
        codeManagement.clean()
        // Process message and produce result.
        switch m {
        case let .user(mm):
            codeManagement.process(.performEditing(mm))
        case .undo:
            codeManagement.process(.performEditing(.undo))
        case .redo:
            codeManagement.process(.performEditing(.redo))
        case .copy:
            let copiedString = codeManagement
                .editing
                .storage
                .lineContentsInCurrentSelection()
                .joined(separator: "\n")
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(copiedString, forType: .string)
        case .cut:
            let copiedString = codeManagement
                .editing
                .storage
                .lineContentsInCurrentSelection()
                .joined(separator: "\n")
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(copiedString, forType: .string)
            var x = codeManagement.editing.storage
            x.replaceCharactersInCurrentSelection(with: "")
            codeManagement.process(.performEditing(.edit(x, nameForMenu: "Cut")))
        case .paste:
            guard let stringToPaste = NSPasteboard.general.string(forType: .string) else { return }
            var x = codeManagement.editing.storage
            x.replaceCharactersInCurrentSelection(with: stringToPaste)
            codeManagement.process(.performEditing(.edit(x, nameForMenu: "Paste")))
        case .selectAll:
            guard let stringToPaste = NSPasteboard.general.string(forType: .string) else { return }
            var x = codeManagement.editing.storage
            x.selectAll()
            codeManagement.process(.performEditing(.edit(x, nameForMenu: "Select All")))
        case .testTextReloading:
            codeManagement.process(.performEditing(.reset(CodeStorage())))
            codeManagement.process(.performEditing(.typing(.placeText("Resets to a new document."))))
        case .testTextEditing:
            var src = codeManagement.editing.storage
            src.replaceCharactersInCurrentSelection(with: "\nPerforms an editing...")
            codeManagement.process(.performEditing(.edit(src, nameForMenu: "Test")))
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

            let text = codeManagement.editing.storage.text
            for _ in 0..<2 {
                for lineOffset in text.lines.offsets {
                    let line = text.lines.atOffset(lineOffset)
                    let utf8Count = line.characters.utf8.count
                    let a = (0..<utf8Count).randomElement() ?? 0
                    let b = (0..<utf8Count).randomElement() ?? 0
                    let c = CodeStoragePosition(lineOffset: lineOffset, characterUTF8Offset: min(a,b))
                    let d = CodeStoragePosition(lineOffset: lineOffset, characterUTF8Offset: max(a,b))
                    codeManagement.process(.setStyle(CodeStyle.all.randomElement() ?? .plain, in: c..<d))
                }
            }
        case .testToggleVisibility:
            scrollCodeView.isHidden = !scrollCodeView.isHidden
        }
        
        // Post-process auto-completion.
        if let p = codeManagement.editing.storage.timeline.points.last {
            let config = codeManagement.editing.config
            switch p.replacementContent {
            case "\n":
                // Indent only.
                var s = codeManagement.editing.storage
                let upLineContent = s.text.lines.atOffset(s.caretPosition.lineOffset-1).characters
                let lv = upLineContent.countPrefix(" ") / config.editing.tabSpaceCount
                let a = String(repeating: " ", count: lv * config.editing.tabSpaceCount)
                s.replaceCharactersInCurrentSelection(with: a)
                codeManagement.process(.performEditing(.edit(s, nameForMenu: "Completion")))
            case "{":
                // Closing with indent.
                var s = codeManagement.editing.storage
                let lineContent = s.text.lines.atOffset(s.caretPosition.lineOffset).characters
                let lv = lineContent.countPrefix(" ") / config.editing.tabSpaceCount
                let a = String(repeating: " ", count: lv * config.editing.tabSpaceCount)
                let b = String(repeating: " ", count: lv.advanced(by: 1) * config.editing.tabSpaceCount)
                s.replaceCharactersInCurrentSelection(with: "\n\(b)")
                let p = s.caretPosition
                s.replaceCharactersInCurrentSelection(with: "\n\(a)}")
                s.moveCaret(to: p)
                codeManagement.process(.performEditing(.edit(s, nameForMenu: "Completion")))
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
    @IBAction
    public func testToggleVisibility(_:AnyObject?) {
        process(.testToggleVisibility)
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
    @IBAction
    func copy(_:AnyObject?) {
        process(.copy)
    }
    @IBAction
    func cut(_:AnyObject?) {
        process(.cut)
    }
    @IBAction
    func paste(_:AnyObject?) {
        process(.paste)
    }
    @IBAction
    override func selectAll(_ sender: Any?) {
        process(.selectAll)
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
        let lineContent = text.lines.atOffset(caretPosition.lineOffset).characters
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

