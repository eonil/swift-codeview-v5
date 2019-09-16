////
////  TextTypingView.swift
////  TextInputView1
////
////  Created by Henry Hathaway on 9/4/19.
////  Copyright © 2019 Henry Hathaway. All rights reserved.
////
//
//import Foundation
//import AppKit
//
//final class TextTypingView: NSView, NSTextInputClient {
//    let control = PassthroughSubject<TextTypingControl,Never>()
//    let note = PassthroughSubject<TextTypingNote,Never>()
//    
//    override var acceptsFirstResponder: Bool {
//        return true
//    }
//    override func keyDown(with event: NSEvent) {
//        assert(inputContext != nil)
//        inputContext?.handleEvent(event)
//    }
//    
//    
//    override func doCommand(by selector: Selector) {
//        print("\(#function): \(selector)")
//        note.send(.issueEditingCommand(selector))
//    }
//    
//    private var isMarked = false
//    /// Marked text.
//    private var markedTextBuffer = NSString()
//    /// Selection position in marked text.
//    /// This is separated from selection in document.
//    private var markedTextSelectedRange = NSRange(location: 0, length: 0)
//    
//    func insertText(_ string: Any, replacementRange: NSRange) {
////        print("\(#function): string: \(string), replacementRange: \(replacementRange)")
//        
//        /// Insert into target position.
//        let newString = extractString(string)
//        note.send(.placeText(newString as String))
//        
//        /// Erase marked text.
//        isMarked = false
//        markedTextBuffer = NSString()
//        markedTextSelectedRange = NSRange(location: 0, length: 0)
//    }
//    func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
////        print("\(#function): string: \(string), selectedRange: \(selectedRange), replacementRange: \(replacementRange)")
//        let newString = extractString(string)
//        isMarked = true
//        markedTextBuffer = newString
//        markedTextSelectedRange = selectedRange
//    }
//    func unmarkText() {
////        print("\(#function)")
//        let newString = markedTextBuffer
//        isMarked = false
//        markedTextBuffer = NSString()
//        markedTextSelectedRange = NSRange(location: 0, length: 0)
//        note.send(.placeText(newString as String))
//    }
//    func selectedRange() -> NSRange {
////        print("\(#function)")
//        return markedTextSelectedRange
//    }
//    func markedRange() -> NSRange {
////        print("\(#function)")
//        return isMarked
//            ? NSRange(location: 0, length: markedTextBuffer.length)
//            : NSRange(location: NSNotFound, length: 0)
//    }
//    func hasMarkedText() -> Bool {
//        return isMarked
//    }
//    func attributedSubstring(forProposedRange range: NSRange, actualRange: NSRangePointer?) -> NSAttributedString? {
//        /// IME server may desire to read any charcter in the document.
//        /// I am not sure how IME wants this feature, but I don't think this would be typical situation.
//        /// Therefore, reading back arbitrary portion from document not optimized.
//        return nil
//    }
//    func validAttributesForMarkedText() -> [NSAttributedString.Key] {
//        return []
//    }
//    func firstRect(forCharacterRange range: NSRange, actualRange: NSRangePointer?) -> NSRect {
//        return .zero
//    }
//    func characterIndex(for point: NSPoint) -> Int {
//        return NSNotFound
//    }
//}
//
//private func extractString(_ s:Any) -> NSString {
//    if let a = s as? NSAttributedString {
//        return a.string as NSString
//    }
//    if let b = s as? NSString {
//        return b
//    }
//    if let c = s as? String {
//        return c as NSString
//    }
//    fatalError("Unsupported type of input.")
//}
