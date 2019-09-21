//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/19/19.
//

import Foundation
import AppKit

/// List of editing command.
/// I am not very sure on this yet.
public enum TextTypingCommand {
    case moveLeft
    case moveLeftAndModifySelection
    case moveRight
    case moveRightAndModifySelection
    case moveWordLeft
    case moveWordLeftAndModifySelection
    case moveWordRight
    case moveWordRightAndModifySelection
    case moveBackward
    case moveBackwardAndModifySelection
    case moveForward
    case moveForwardAndModifySelection
    case moveToLeftEndOfLine
    case moveToLeftEndOfLineAndModifySelection
    case moveToRightEndOfLine
    case moveToRightEndOfLineAndModifySelection
    case moveUp
    case moveUpAndModifySelection
    case moveDown
    case moveDownAndModifySelection
    case moveToBeginningOfParagraph
    case moveToBeginningOfParagraphAndModifySelection
    case moveToEndOfParagraph
    case moveToEndOfParagraphAndModifySelection
    case moveToBeginningOfDocument
    case moveToBeginningOfDocumentAndModifySelection
    case moveToEndOfDocument
    case moveToEndOfDocumentAndModifySelection
    case selectAll
    case insertNewline
    case insertTab
    case insertBacktab
    case deleteForward
    case deleteBackward
    case deleteWordForward
    case deleteWordBackward
    case deleteToBeginningOfLine
    case deleteToEndOfLine
    case cancelOperation
}

extension TextTypingCommand {
    init?(_ sel:Selector) {
        guard let x = make(sel) else { return nil }
        self = x
    }
}

/// Passed selector is unknown. There's no definition in Apple documentation.
/// But I think you can assume it as one method of `NSStandardKeyBindingResponding`.
private func make(_ sel:Selector) -> TextTypingCommand? {
    typealias K = NSStandardKeyBindingResponding
    switch sel {
    case #selector(K.moveLeft(_:)):                                     return .moveLeft
    case #selector(K.moveRight(_:)):                                    return .moveRight
    case #selector(K.moveLeftAndModifySelection(_:)):                   return .moveLeftAndModifySelection
    case #selector(K.moveRightAndModifySelection(_:)):                  return .moveRightAndModifySelection
    case #selector(K.moveWordLeft(_:)):                                 return .moveWordLeft
    case #selector(K.moveWordRight(_:)):                                return .moveWordRight
    case #selector(K.moveWordLeftAndModifySelection(_:)):               return .moveWordLeftAndModifySelection
    case #selector(K.moveWordRightAndModifySelection(_:)):              return .moveWordRightAndModifySelection
    case #selector(K.moveBackward(_:)):                                 return .moveBackward
    case #selector(K.moveBackwardAndModifySelection(_:)):               return .moveBackwardAndModifySelection
    case #selector(K.moveForward(_:)):                                  return .moveForward
    case #selector(K.moveForwardAndModifySelection(_:)):                return .moveForwardAndModifySelection
    case #selector(K.moveToBeginningOfParagraph(_:)):                   return .moveToBeginningOfParagraph
    case #selector(K.moveToBeginningOfParagraphAndModifySelection(_:)): return .moveToBeginningOfParagraphAndModifySelection
    case #selector(K.moveToEndOfParagraph(_:)):                         return .moveToEndOfParagraph
    case #selector(K.moveToEndOfParagraphAndModifySelection(_:)):       return .moveToEndOfParagraphAndModifySelection
    case #selector(K.moveToLeftEndOfLine(_:)):                          return .moveToLeftEndOfLine
    case #selector(K.moveToRightEndOfLine(_:)):                         return .moveToRightEndOfLine
    case #selector(K.moveToLeftEndOfLineAndModifySelection(_:)):        return .moveToLeftEndOfLineAndModifySelection
    case #selector(K.moveToRightEndOfLineAndModifySelection(_:)):       return .moveToRightEndOfLineAndModifySelection
    case #selector(K.moveUp(_:)):                                       return .moveUp
    case #selector(K.moveDown(_:)):                                     return .moveDown
    case #selector(K.moveUpAndModifySelection(_:)):                     return .moveUpAndModifySelection
    case #selector(K.moveDownAndModifySelection(_:)):                   return .moveDownAndModifySelection
    case #selector(K.moveToBeginningOfDocument(_:)):                    return .moveToBeginningOfDocument
    case #selector(K.moveToBeginningOfDocumentAndModifySelection(_:)):  return .moveToBeginningOfDocumentAndModifySelection
    case #selector(K.moveToEndOfDocument(_:)):                          return .moveToEndOfDocument
    case #selector(K.moveToEndOfDocumentAndModifySelection(_:)):        return .moveToEndOfDocumentAndModifySelection
    case #selector(K.selectAll(_:)):                                    return .selectAll
    case #selector(K.insertNewline(_:)):                                return .insertNewline
    case #selector(K.insertTab(_:)):                                    return .insertTab
    case #selector(K.insertBacktab(_:)):                                return .insertBacktab
    case #selector(K.deleteBackwardByDecomposingPreviousCharacter(_:)): return nil
    case #selector(K.deleteForward(_:)):                                return .deleteForward
    case #selector(K.deleteBackward(_:)):                               return .deleteBackward
    case #selector(K.deleteWordBackward(_:)):                           return .deleteWordBackward
    case #selector(K.deleteWordForward(_:)):                            return .deleteWordForward
    case #selector(K.deleteToBeginningOfLine(_:)):                      return .deleteToBeginningOfLine
    case #selector(K.deleteToEndOfLine(_:)):                            return .deleteToEndOfLine
    case #selector(K.cancelOperation(_:)):                              return .cancelOperation
    /// Mysterious message sent by AppKit.
    case #selector(Dummy.noop(_:)):
        return nil
    default:
        assert({
            print("Unhandled editing command: \(sel)")
            return true
        }())
        return nil
    }
}

/// Defined to make `noop(_:)` selector to cheat compiler.
private final class Dummy {
    @objc
    func noop(_:AnyObject) {}
}

