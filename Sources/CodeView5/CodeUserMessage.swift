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
}
