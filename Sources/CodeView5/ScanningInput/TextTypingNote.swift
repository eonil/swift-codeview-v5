//
//  TextTypingNote.swift
//  TextInputView1
//
//  Created by Henry Hathaway on 9/4/19.
//  Copyright © 2019 Henry Hathaway. All rights reserved.
//

import Foundation

enum TextTypingNote {
    /// Sets "marked text" that is text-in-completion by IME.
    /// You are supposed to delete current selection
    /// and render this text at selection position until you receive `placeText`.
    /// - Parameter selection:
    ///     Selection range in `content`.
    case previewIncompleteText(content: String, selection: Range<String.Index>)
    /// Inserts new characters at current selection.
    case placeText(String)
    /// Notes command issued by end-user.
    /// Passed selector is unknown. There's no definition in Apple documentation.
    /// But I think you can assume it as one method of `NSStandardKeyBindingResponding`.
    case issueEditingCommand(Selector)
}
