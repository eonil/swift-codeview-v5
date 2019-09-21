//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/20/19.
//

import Foundation

public enum CodeUserMessage {
    case edit(CodeEditingMessage)
    /// Notes from AppKit action messages.
    case menu(MenuMessage)
    public enum MenuMessage {
        case selectAll
        case copy
        case cut
        case paste(String)
        case undo
        case redo
    }
    /// Notes sent from AppKit to a `NSView` by managing view instance.
    case view(ViewMessage)
    public enum ViewMessage {
        case becomeFirstResponder
        case resignFirstResponder
        case resize
    }
}
