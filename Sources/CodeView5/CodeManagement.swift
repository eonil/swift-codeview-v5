//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/20/19.
//

import Foundation

/// Pre-built code-text processing engine.
///
/// This is designed to provide minimum default code-text editing engine.
/// You can build more features around this.
///
/// Tracking Content Changes
/// ------------------------
/// To track contet (text) changes, see `CodeSource.timeline`.
/// It contains changes happen in `CodeSource.storage` since last emission.
/// The timeline will be emptied each time after note emission.
/// **If `CodeSource.timeline` is empty, it means whole snapshot replacement**.
/// This can happen by content reloading or undo/redo operation.
/// In that case, you must abandon any existing content
/// and should replace all from the source.
///
public struct CodeManagement {
    public private(set) var editing = CodeEditing()
    /// This is supposed to stored less than hundred values.
    /// If this need to store more, this should use copy-friendly types.
    public private(set) var breakPointLineOffsets = Set<Int>()
    /// Defines whow completion window to be rendered.
    /// `nil` means completion window should be disappeared.
    public private(set) var completionWindowState = CompletionWindowState?.none
    public typealias CompletionWindowState = CodeView.CompletionWindowState
    /// This is an output state.
    public private(set) var effects = [Effect]()
    public typealias Effect = CodeView.Control.Effect
    
    public init() {}
    public var preventedTypingCommands: Set<TextTypingCommand> {
        return completionWindowState == nil ? [] : [.moveUp, .moveDown]
    }
    public enum Message {
        case userInteraction(CodeUserMessage)
        case setBreakPointLineOffsets(Set<Int>)
        case setCompletionRange(Range<CodeStoragePosition>?)
    }
    public mutating func process(_ m:Message) {
        /// Clean up prior output.
        effects.removeAll()
        editing.source.cleanTimeline()
        /// Check and continue.
        guard shouldProcessMessage(m) else { return }
        switch m {
        case let .userInteraction(mm):
            switch mm {
            case let .edit(mmm): processEdit(mmm)
            case let .menu(mmm): processMenu(mmm)
            case let .view(mmm): processView(mmm)
            }
        case let .setBreakPointLineOffsets(bps):
            breakPointLineOffsets = bps
        case let .setCompletionRange(mm):
            completionWindowState = mm == nil ? nil : CompletionWindowState(aroundRange: mm!)
        }
        /// Remove completion window if target range is invalid.
        /// This can happen as user delete existing characters included in the range.
        /// Hiding completion window is natural choice.
        if let r = completionWindowState?.aroundRange {
            if !editing.source.isValidRange(r) {
                completionWindowState = nil
            }
        }
    }
    private func shouldProcessMessage(_ m:Message) -> Bool {
        switch m {
        case let .userInteraction(mm):
            switch mm {
            case let .edit(mmm):
                switch mmm {
                case let .typing(mmmm):
                    switch mmmm {
                    case let .processEditingCommand(cmd):
                        return !preventedTypingCommands.contains(cmd)
                    default: return true
                    }
                default: return true
                }
            default: return true
            }
        case .setBreakPointLineOffsets: return true
        case .setCompletionRange: return true
        }
    }
    
    private mutating func processEdit(_ mm:CodeEditingMessage) {
        editing.apply(mm)
        let changes = editing.source.timeline.points
        
        // Adjust breakpoint positions.
        do {
            for change in changes {
                let rangeToReplace = change.replacementRange
                let replacementString = change.replacementContent
                let removeLineCount = rangeToReplace.lineOffsetRange.count
                let newLineCharCount = replacementString.filter({ $0 == "\n" }).count
                breakPointLineOffsets = Set(breakPointLineOffsets.compactMap({ i in
                    if i <= rangeToReplace.lowerBound.lineOffset {
                        return i
                    }
                    else {
                        let k = i + -removeLineCount + newLineCharCount
                        return k <= rangeToReplace.lowerBound.lineOffset ? nil : k
                    }
                }))
            }
            switch mm {
            case let .mouse(mmm):
                switch mmm.kind {
                case .down:
                    let layout = CodeLayout(
                        config: editing.config,
                        source: editing.source,
                        imeState: editing.imeState,
                        boundingWidth: mmm.bounds.width)
                    if mmm.pointInBounds.x < editing.config.rendering.breakpointWidth {
                        let lineOffset = layout.clampingLineOffset(at: mmm.pointInBounds.y)
                        // Toggle breakpoint.
                        toggleBreakPoint(at: lineOffset)
                    }
                default: break
                }
            default: break
            }
        }
        
        
        switch mm {
        case let .typing(mmm):
            switch mmm {
            case let .placeText(s):
                if [".", ":"].contains(s) {
                    // Start completion.
                    let p = editing.source.caretPosition
                    completionWindowState = CompletionWindowState(aroundRange: p..<p)
                }
            case let .processEditingCommand(mmmm):
                switch mmmm {
                case .cancelOperation:
                    completionWindowState = nil
                default: break
                }
            default: break
            }
        default: break
        }
        
        // Kill completion if caret goes out of its range.
        if let r = completionWindowState?.aroundRange {
            if !r.includedLineOffsetRange.contains(editing.source.caretPosition.lineOffset) {
                completionWindowState = nil
            }
            if editing.source.caretPosition.characterUTF8Offset < r.lowerBound.characterUTF8Offset {
                completionWindowState = nil
            }
        }
    }
    private mutating func processMenu(_ mm:CodeView.Note.MenuMessage) {
        switch mm {
        case .copy:
            let sss = editing.source.lineContentsInCurrentSelection()
            let s = sss.joined(separator: "\n")
            effects.append(.replacePasteboardContent(s))
        case .cut:
            let sss = editing.source.lineContentsInCurrentSelection()
            let s = sss.joined(separator: "\n")
            editing.source.replaceCharactersInCurrentSelection(with: "")
            editing.recordTimePoint(as: .alienEditing(nameForMenu: "Cut"))
            editing.invalidate(.all)
            effects.append(.replacePasteboardContent(s))
        case let .paste(s):
            editing.source.replaceCharactersInCurrentSelection(with: s)
            editing.recordTimePoint(as: .alienEditing(nameForMenu: "Paste"))
            editing.invalidate(.all)
        case .selectAll:
            editing.source.selectAll()
            editing.invalidate(.all)
//        case let .replace(withContent, nameForMenu):
        case .undo:
            guard editing.timeline.canUndo else { break }
            editing.undoInTimeline()
            editing.invalidate(.all)
        case .redo:
            guard editing.timeline.canRedo else { break }
            editing.redoInTimeline()
            editing.invalidate(.all)
        }
    }
    private mutating func processView(_ mm:CodeView.Note.ViewMessage) {
        switch mm {
        case .becomeFirstResponder:
            completionWindowState = nil
        case .resignFirstResponder:
            completionWindowState = nil
        case .resize:
            completionWindowState = nil
        }
    }
}

// MARK: BreakPoint Editing
extension CodeManagement {
    mutating func toggleBreakPoint(at lineOffset: Int) {
        if breakPointLineOffsets.contains(lineOffset) {
            breakPointLineOffsets.remove(lineOffset)
        }
        else {
            breakPointLineOffsets.insert(lineOffset)
        }
    }
    mutating func insertBreakPoint(at lineOffset: Int)  {
        breakPointLineOffsets.insert(lineOffset)
    }
    mutating func removeBreakPoint(for lineOffset: Int) {
        breakPointLineOffsets.remove(lineOffset)
    }
}
