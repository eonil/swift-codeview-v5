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
enum TextTypingCommand {
    case moveLeft
    case moveRight
    case moveLeftAndModifySelection
    case moveRightAndModifySelection
    case moveToLeftEndOfLine
    case moveToRightEndOfLine
    case moveToLeftEndOfLineAndModifySelection
    case moveToRightEndOfLineAndModifySelection
    case moveUp
    case moveDown
    case moveUpAndModifySelection
    case moveDownAndModifySelection
    case moveToBeginningOfDocument
    case moveToEndOfDocument
    case moveToBeginningOfDocumentAndModifySelection
    case moveToEndOfDocumentAndModifySelection
    case selectAll
    case insertNewLine
    case insertTab
    case insertBacktab
    case deleteForward
    case deleteBackward
    case deleteToBeginningOfLine
    case deleteToEndOfLine
    case cancelOperation
}

extension TextTypingCommand {
    init?(_ sel:Selector) {
        if let x = make(sel) {
            self = x
        }
        return nil
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
    case #selector(K.moveToLeftEndOfLine(_:)):                          return .moveToLeftEndOfLine
    case #selector(K.moveToRightEndOfLine(_:)):                         return .moveToRightEndOfLine
    case #selector(K.moveToLeftEndOfLineAndModifySelection(_:)):          return .moveToLeftEndOfLineAndModifySelection
    case #selector(K.moveToRightEndOfLineAndModifySelection(_:)):         return .moveToRightEndOfLineAndModifySelection
    case #selector(K.moveUp(_:)):                                         return .moveUp
    case #selector(K.moveDown(_:)):                                     return .moveDown
    case #selector(K.moveUpAndModifySelection(_:)):                     return .moveUpAndModifySelection
    case #selector(K.moveDownAndModifySelection(_:)):                   return .moveDownAndModifySelection
    case #selector(K.moveToBeginningOfDocument(_:)):                    return .moveToBeginningOfDocument
    case #selector(K.moveToBeginningOfDocumentAndModifySelection(_:)):  return .moveToBeginningOfDocumentAndModifySelection
    case #selector(K.moveToEndOfDocument(_:)):                          return .moveToEndOfDocument
    case #selector(K.moveToEndOfDocumentAndModifySelection(_:)):        return .moveToEndOfDocumentAndModifySelection
    case #selector(K.selectAll(_:)):                                    return .selectAll
    case #selector(K.insertNewline(_:)):                                return .insertNewLine
    case #selector(K.insertTab(_:)):                                    return .insertTab
    case #selector(K.insertBacktab(_:)):                                return .insertBacktab
    case #selector(K.deleteForward(_:)):                                return .deleteForward
    case #selector(K.deleteBackward(_:)):                               return .deleteBackward
    case #selector(K.deleteToBeginningOfLine(_:)):                      return .deleteToBeginningOfLine
    case #selector(K.deleteToEndOfLine(_:)):                            return .deleteToEndOfLine
    case #selector(K.cancelOperation(_:)):                              return .cancelOperation
    /// Mysterious message sent by AppKit.
    case #selector(Dummy.noop(_:)):                                     return nil
    default:
        assert(false,"Unhandled editing command: \(sel)")
        return nil
    }
}

/// Defined to make `noop(_:)` selector to cheat compiler.
private final class Dummy {
    @objc
    func noop(_:AnyObject) {}
}

