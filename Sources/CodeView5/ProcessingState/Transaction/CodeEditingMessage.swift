//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/21/19.
//

import Foundation

public enum CodeEditingMessage {
    case reset(CodeStorage)
    /// Generic editing with undo name.
    case edit(CodeStorage, nameForMenu: String)
    /// Notes produced from IME.
    /// This may contain some AppKit action messages.
    case typing(TextTypingMessage)
    /// Notes produced by mouse operation on `NSView`.
    case mouse(MouseMessage)
    public struct MouseMessage {
        public var kind: Kind
        public var pointInBounds: CGPoint
        public var bounds: CGRect
        public enum Kind {
            case down, dragged, up
        }
    }
}
