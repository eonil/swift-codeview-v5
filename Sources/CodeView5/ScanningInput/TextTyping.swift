//
//  TextTyping.swift
//  TextInputView1
//
//  Created by Henry Hathaway on 9/4/19.
//  Copyright © 2019 Henry Hathaway. All rights reserved.
//

import Foundation
import AppKit

final class TextTyping {
    private let client: TextTypingClient
    private let context: NSTextInputContext
    
    init() {
        client = TextTypingClient()
        context = NSTextInputContext(client: client)
    }
    deinit {
        deactivate()
    }
    func control(_ c:TextTypingControl) {
        client.control(c)
    }
    var note: ((TextTypingMessage) -> Void)? {
        get { client.note }
        set(x) { client.note = x }
    }
    func activate() {
        context.activate()
    }
    func deactivate() {
        context.deactivate()
    }
//    /// Complete current completion session by accepting any text in completion.
//    func complete() {
//        context.discardMarkedText()
//        if client.isMarked {
//            note.send(.placeText(client.markedTextBuffer as String))
//        }
//    }
    func processEvent(_ e:NSEvent) {
        context.handleEvent(e)
    }
}

private final class TextTypingClient: NSObject, NSTextInputClient {
    func control(_ c:TextTypingControl) {
        DispatchQueue.main.async { [weak self] in
            RunLoop.main.perform { [weak self] in
                self?.process(c)
            }
        }
    }
    var note: ((TextTypingMessage) -> Void)?
    
    func doCommand(by selector: Selector) {
        guard let cmd = TextTypingCommand(selector) else { return }
        note?(.processEditingCommand(cmd))
    }
    
    private(set) var isMarked = false
    /// Marked text.
    private(set) var markedTextBuffer = NSString()
    /// Selection position in marked text.
    /// This is separated from selection in document.
    private(set) var markedTextSelectedRange = NSRange(location: 0, length: 0)
    private var typingFrame = CGRect.zero
    
    private func process(_ c:TextTypingControl) {
        switch c {
        case .setContent(_):
            break
        case let .setTypingFrame(f):
            typingFrame = f
        }
    }
    
    override init() {
        super.init()
    }
    func insertText(_ string: Any, replacementRange: NSRange) {
        /// Insert into target position.
        let newString = extractString(string)
        note?(.placeText(newString as String))
        
        /// Erase marked text.
        isMarked = false
        markedTextBuffer = NSString()
        markedTextSelectedRange = NSRange(location: 0, length: 0)
    }
    func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
        let newString = extractString(string)
        isMarked = true
        markedTextBuffer = newString
        markedTextSelectedRange = selectedRange
        
        let s = markedTextBuffer as String
        let r = Range(markedTextSelectedRange, in: s)!
        note?(.previewIncompleteText(content: markedTextBuffer as String, selection: r))
    }
    func unmarkText() {
        let newString = markedTextBuffer
        isMarked = false
        markedTextBuffer = NSString()
        markedTextSelectedRange = NSRange(location: 0, length: 0)
        note?(.placeText(newString as String))
    }
    func selectedRange() -> NSRange {
        return markedTextSelectedRange
    }
    func markedRange() -> NSRange {
        return isMarked
            ? NSRange(location: 0, length: markedTextBuffer.length)
            : NSRange(location: NSNotFound, length: 0)
    }
    func hasMarkedText() -> Bool {
        return isMarked
    }
    func attributedSubstring(forProposedRange range: NSRange, actualRange: NSRangePointer?) -> NSAttributedString? {
        /// IME server may desire to read any charcter in the document.
        /// I am not sure how IME wants this feature, but I don't think this would be typical situation.
        /// Therefore, reading back arbitrary portion from document not optimized.
        return nil
    }
    func validAttributesForMarkedText() -> [NSAttributedString.Key] {
        return []
    }
    func firstRect(forCharacterRange range: NSRange, actualRange: NSRangePointer?) -> NSRect {
        return typingFrame
    }
    func characterIndex(for point: NSPoint) -> Int {
        return NSNotFound
    }
}

private func extractString(_ s:Any) -> NSString {
    if let a = s as? NSAttributedString {
        return a.string as NSString
    }
    if let b = s as? NSString {
        return b
    }
    if let c = s as? String {
        return c as NSString
    }
    fatalError("Unsupported type of input.")
}
