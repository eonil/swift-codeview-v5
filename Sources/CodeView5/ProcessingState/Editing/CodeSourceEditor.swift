//
//  CodeSourceEditor.swift
//  
//
//  Created by Henry Hathaway on 9/11/19.
//

import Foundation

/// Essentially a code-source with note emission.
struct CodeSourceEditor: CodeSourceEditing {
    /// Notifies editing.
    /// This note will be sent after all states are updated.
    var note: ((CodeView.Note) -> Void)?
    
    private var suspendNote = false
    var source = CodeSource() {
        didSet {
            if !suspendNote {
                note?(.replaceAllSilently(source))
            }
        }
    }
    var config: CodeSourceConfig { source.config }
    var storage: CodeStorage { source.storage }
    var caretPosition: CodeStoragePosition { get { source.caretPosition } set(x) { source.caretPosition = x } }
    var selectionAnchorPosition: CodeStoragePosition? { get { source.selectionAnchorPosition } set(x) { source.selectionAnchorPosition = x } }
    var selectionRange: Range<CodeStoragePosition> { get { source.selectionRange } set(x) { source.selectionRange = x } }
    mutating func replaceCharactersInCurrentSelection(with s:String) {
        suspendNote = true
        let oldSource = source
        source.replaceCharactersInCurrentSelection(with: s)
        let newSource = source
        suspendNote = false
        let ed = CodeView.Note.Editing(
            replacementContent: s,
            sourceBeforeReplacement: oldSource,
            sourceAfterReplacement: newSource)
        note?(.editing(ed))
    }
}
