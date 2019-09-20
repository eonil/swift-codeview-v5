//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/20/19.
//

import Foundation


public enum CodeUserInteractionScanningMessage {
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
    }
    case setPreventedTypingCommands(Set<TextTypingCommand>)
}

public enum CodeEditingStateRenderingMessage {
    /// Apply effects on client side.
    case applyEffect(CodeView2Management.Effect)
    /// Render snapshot on client side.
    case stateSnapshot(CodeView2Management.State)
}
