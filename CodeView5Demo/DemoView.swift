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
    private var codeManagement = CodeView2Management()
//    private let completionWindowManagement = CompletionWindowManagement()
    
    private func process(_ m:CodeView2.Note) {
        let effects = codeManagement.process(m)
        for effect in effects {
            scrollCodeView.codeView.control(.applyEffect(effect))
        }
        scrollCodeView.codeView.control(.stateSnapshot(codeManagement.state))
        
        //
        let src = codeManagement.state.state.source
        print("ver: \(src.version)")
        for p in src.timeline.points {
            let oldContent = p.baseSnapshot.lineContents(in: p.replacementRange).joined(separator: "\n")
            let newContent = p.replacementContent
            print("#\(p.key): `\(oldContent)` -> `\(newContent)`")
        }
        
        // Completion window.
        let caret = src.caretPosition
        let line = src.storage.lines.atOffset(caret.lineOffset)
        if let i = line.content.lastIndex(of: ".") {
            // Override.
            let charOffset = line.content.utf8OffsetFromIndex(i)
            let p = CodeStoragePosition(lineOffset: caret.lineOffset, characterUTF8Offset: charOffset)
            let r = p..<p
            let effects = codeManagement.process(.setPreventedTypingCommands([.moveUp, .moveDown]))
            for effect in effects {
                scrollCodeView.codeView.control(.applyEffect(effect))
            }
            var snapshot = codeManagement.state
            snapshot.completionWindowState?.aroundRange = r
            scrollCodeView.codeView.control(.stateSnapshot(snapshot))
        }
        else {
            let effects = codeManagement.process(.setPreventedTypingCommands([]))
            for effect in effects {
                scrollCodeView.codeView.control(.applyEffect(effect))
            }
            let snapshot = codeManagement.state
            scrollCodeView.codeView.control(.stateSnapshot(snapshot))
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
        let effects1 = codeManagement.process(.edit(.reset(CodeSource())))
        let effects2 = codeManagement.process(.edit(.typing(.placeText("Resets to a new document."))))
        let allEffects = effects1 + effects2
        for effect in allEffects {
            scrollCodeView.codeView.control(.applyEffect(effect))
        }
        scrollCodeView.codeView.control(.stateSnapshot(codeManagement.state))
    }
    @IBAction
    public func testTextEditing(_:AnyObject) {
        var src = codeManagement.state.state.source
        src.replaceCharactersInCurrentSelection(with: "\nPerforms an editing...")
        let effects = codeManagement.process(.edit(.edit(src, nameForMenu: "Test")))
        for effect in effects {
            scrollCodeView.codeView.control(.applyEffect(effect))
        }
        scrollCodeView.codeView.control(.stateSnapshot(codeManagement.state))
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
        scrollCodeView.codeView.completionView = NSButton()
    }
}
