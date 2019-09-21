//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/21/19.
//

import Foundation

public extension CodeManagement {
    func send(to codeView:CodeView) {
        for effect in effects {
            codeView.control(.applyEffect(effect))
        }
        codeView.control(.renderEditing(editing))
        codeView.control(.renderBreakPointLineOffsets(breakPointLineOffsets))
        codeView.control(.renderCompletionWindow(completionWindowState))
    }
}



