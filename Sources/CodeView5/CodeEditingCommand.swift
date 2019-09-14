//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/14/19.
//

import Foundation
import AppKit

/// List of editing command.
/// I am not very sure on this yet.
enum CodeEditingCommand {
    case modifySelectionWithAnchor(toPosition:CodeStoragePosition)
    case moveToEndOfUpLine
    case moveToStartOfDownLine
    case moveLeft
    case moveRight
    case moveLeftAndModifySelection
    case moveRightAndModifySelection
    case moveToLeftEndOfLine
    case moveToRightEndOfLine
    case moveToLeftEndOfLineAndModifySelection
    case moveToRightEndOfLineAndModifySelection
    case moveUp(font: NSFont, atX: CGFloat)
    case moveDown(font: NSFont, atX: CGFloat)
    case moveUpAndModifySelection(font: NSFont, atX: CGFloat)
    case moveDownAndModifySelection(font: NSFont, atX: CGFloat)
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
}

