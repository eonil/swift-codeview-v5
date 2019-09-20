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
    private let completionWindowManagement = CompletionWindowManagement()
    private var codeSource = CodeSource()
    
    private func process(_ n:CodeView.Note) {
        switch n {
        case let .editing(conf,src,ime):
            print("ver: \(src.version)")
            for p in src.timeline.points {
                let oldContent = p.baseSnapshot.lineContents(in: p.replacementRange).joined(separator: "\n")
                let newContent = p.replacementContent
                print("#\(p.key): `\(oldContent)` -> `\(newContent)`")
            }
            codeSource = src
            let caret = src.caretPosition
            let line = src.storage.lines.atOffset(caret.lineOffset)
            func makeCompletionState() -> CompletionWindowManagement.State? {
                guard let i = line.content.lastIndex(of: ".") else { return nil }
                let charOffset = line.content.utf8OffsetFromIndex(i)
                let p = CodeStoragePosition(lineOffset: caret.lineOffset, characterUTF8Offset: charOffset)
                let s = CompletionWindowManagement.State(
                    config: conf,
                    source: src,
                    imeState: ime,
                    completionRange: p..<p)
                return s
            }
            let s = makeCompletionState()
            completionWindowManagement.setState(s)
            scrollCodeView.codeView.control(.setPreventedTextTypingCommands(s == nil ? [] : [.moveUp, .moveDown]))
            
        case .becomeFirstResponder:
            completionWindowManagement.invalidate()
        case .resignFirstResponder:
            completionWindowManagement.invalidate()
            
        case let .typingCommand(cmd):
            switch cmd {
            case .cancelOperation:
                completionWindowManagement.setState(nil)
                scrollCodeView.codeView.control(.setPreventedTextTypingCommands([]))
            case .moveUp:
                print("MOVE UP")
            case .moveDown:
                print("MOVE DOWN")
            default:
                break
            }
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
        scrollCodeView.codeView.note = { [weak self] n in
            DispatchQueue.main.async { [weak self] in
                RunLoop.main.perform { [weak self] in
                    self?.process(n)
                }
            }
        }
        completionWindowManagement.codeView = scrollCodeView.codeView
        completionWindowManagement.completionView = NSButton()
    }
}
