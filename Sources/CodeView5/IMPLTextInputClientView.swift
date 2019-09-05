////
////  IMPLTextInputClientView.swift
////  CodeView5
////
////  Created by Henry on 2019/07/25.
////  Copyright © 2019 Eonil. All rights reserved.
////
//
//import Foundation
//import AppKit
//
////enum IMPLTextInputControl {
////    case setSelectedCharacters(String)
////}
//enum IMPLTextInputControl {
//    case replaceSelectedCharacters(String)
//    /// Pushes new characters into your current caret position.
//    case characters(String)
//
//    /// Replaces preview of text in composition.
//    /// Some writing systems (e.g. Korean, Japanese) requires
//    /// multiple level of composition to build single character.
//    /// Composition formula is provided by OS IME, but you need to
//    /// provide previews of current composition before it gets
//    /// built and pushed as new characters.
//    /// This provides that preview. You need to place this characters
//    /// at your caret position.
//    ///
//    /// - Note:
//    ///     Some IME can push multiple characters at once.
//    ///     Be prepared for multiple character input.
//    ///
//    case setCharactersInComposition(String)
//}
//
/////
///// Goals & Non-Goals
///// --------------
///// - No full IME support. No support for floating window and out-of-mark/selection string read-back.
/////
///// - Note:
/////     - Now this works well for English and Korean input, not hasn't been test for anything else.
/////     - No IME floating window support. App crashes.
/////     - I have no idea what to do if IME wants to read strings out of marked/selected range.
/////       Should I keep all text internally taking risk of inconcsistent state?
/////
//final class IMPLTextInputClientView: NSView, NSTextInputClient {
//    private var implText = NSMutableString()
//    private var implSelectedRange = NSRange(location: 0, length: 0)
//    private var implMarkedRange = NSRange(location: NSNotFound, length: 0)
//
//    var note: ((IMPLTextInputControl) -> Void)?
//
//    ///
//
//    override var acceptsFirstResponder: Bool { true }
//    override func becomeFirstResponder() -> Bool {
//        return super.becomeFirstResponder()
//    }
//    override var canBecomeKeyView: Bool { true }
//    override func keyDown(with e: NSEvent) {
//        inputContext?.handleEvent(e)
//    }
//
//    ///
//
//    func insertText(_ string: Any, replacementRange: NSRange) {
//        guard let s = string as? NSString else { fatalError() }
//        print("\(#function), \(s), \(implSelectedRange), \(implMarkedRange), \(replacementRange)")
//        func findFinalReplacementRange() -> NSRange {
//            if replacementRange.location != NSNotFound { return replacementRange }
//            if implMarkedRange.location != NSNotFound { return implMarkedRange }
//            return implSelectedRange
//        }
//        let r = findFinalReplacementRange()
//        implText.replaceCharacters(in: r, with: s as String)
//        implSelectedRange.location = r.location + s.length
//        implSelectedRange.length = 0
//        implMarkedRange = NSRange(location: NSNotFound, length: 0)
////        note?(.characters(s as String))
//        print(implText)
//        print(implSelectedRange)
//        print(implMarkedRange)
//    }
//    func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
//        precondition(selectedRange.location != NSNotFound)
//        func findString() -> NSString? {
//            if let x = string as? NSAttributedString { return x.string as NSString }
//            if let s = string as? NSString { return s }
//            return nil
//        }
//        guard let s = findString() else { fatalError() }
//        print("\(#function), \(s), \(selectedRange), \(replacementRange)")
//        if implMarkedRange.location == NSNotFound {
//            precondition(replacementRange.location == NSNotFound)
//            let r = implSelectedRange
//            let newSelectedRange = NSRange(
//                location: r.location + selectedRange.location,
//                length: selectedRange.length)
//            let newMarkedRange = NSRange(
//                location: implSelectedRange.location,
//                length: s.length)
//            implText.replaceCharacters(in: r, with: s as String)
//            implMarkedRange = newMarkedRange
//            implSelectedRange = newSelectedRange
//        }
//        else {
//            let r = replacementRange.location == NSNotFound ? implMarkedRange : replacementRange
//            let newSelectedRange = NSRange(
//                location: r.location + selectedRange.location,
//                length: selectedRange.length)
//            let newMarkedRange = NSRange(
//                location: implMarkedRange.location,
//                length: implMarkedRange.length - r.length + s.length)
//            implText.replaceCharacters(in: r, with: s as String)
//            implMarkedRange = newMarkedRange
//            implSelectedRange = newSelectedRange
//        }
//
////        note?(.setCharactersInCompositionm(s as String))
//        print(implText)
//        print(implSelectedRange)
//        print(implMarkedRange)
//    }
//
//    func unmarkText() {
//        implMarkedRange = NSRange(location: NSNotFound, length: 0)
//        print("\(#function)")
////        note?(.setCharactersInComposition(""))
//    }
//
//    func selectedRange() -> NSRange {
//        return implSelectedRange
//    }
//
//    func markedRange() -> NSRange {
//        return implMarkedRange
//    }
//
//    func hasMarkedText() -> Bool {
//        return implMarkedRange.location != NSNotFound
//    }
//
//    func attributedSubstring(forProposedRange range: NSRange, actualRange: NSRangePointer?) -> NSAttributedString? {
//        /// I don't know why this is required method.
//        /// InkWell?
//        return nil
//    }
//
//    func validAttributesForMarkedText() -> [NSAttributedString.Key] {
//        return []
//    }
//
//    func firstRect(forCharacterRange range: NSRange, actualRange: NSRangePointer?) -> NSRect {
//        fatalError()
//    }
//
//    func characterIndex(for point: NSPoint) -> Int {
//        fatalError()
//    }
//}
//
//// MARK: Standrad Key Bindings
//extension IMPLTextInputClientView {
////    override func complete(_ sender: Any?) {
//////        super.complete(sender)
////    }
////    override func moveDown(_ sender: Any?) {
//////        super.moveDown(sender)
////    }
//    override func deleteBackward(_ sender: Any?) {
//        guard implSelectedRange.location > 0 else { return }
//        func findRange() -> NSRange {
//            if implSelectedRange.length == 0 {
//                return implText.rangeOfComposedCharacterSequence(at: implSelectedRange.location-1)
//            }
//            else {
//                return implSelectedRange
//            }
//        }
//        let r = findRange()
//        implText.deleteCharacters(in: r)
//        implSelectedRange.location = r.location
//        implSelectedRange.length = 0
////        let s = implText as String
////        let i2 = s.utf16.endIndex
////        let i1 = s.utf16.index(before: i2)
////        let d = s.utf16.distance(from: i1, to: i2)
////        let r = NSRange(location: i1, length: d)
////        implText.deleteCharacters(in: r)
//
//        print("\(#function), \(implText)")
//    }
//}
