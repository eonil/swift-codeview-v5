//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/19/19.
//

import Foundation

/// REPL core of code processing.
///
/// This accepts text-typing notes and extra editing commands
/// to process text editing state -- characters and selections.
///
final class CodeManagement {
    func control(_ c:Control) {
        
    }
    enum Control {
        case typing(TextTypingNote)
    }
    
    var note: ((Note) -> Void)?
    enum Note {
        
    }
}
