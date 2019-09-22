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
/// To track contet (text) changes, see `CodeStorage.timeline`.
/// It contains changes happen in `CodeStorage.storage` since last emission.
/// The timeline will be emptied each time after note emission.
/// **If `CodeStorage.timeline` is empty, it means whole snapshot replacement**.
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
    public private(set) var completionWindow = CompletionWindowState()
    public typealias CompletionWindowState = CodeView.CompletionWindowState
    /// This is an output state.
    public private(set) var effects = [Effect]()
    public typealias Effect = CodeView.Control.Effect
    
    public init() {}
    public var preventedTypingCommands: Set<TextTypingCommand> {
        guard editing.config.editing.preventSomeEditingCommandsOnCompletionVisible else { return [] }
        return completionWindow.isVisible ? [.moveUp, .moveDown, .insertNewline] : []
    }
    public enum Message {
        case userInteraction(CodeUserMessage)
        case setBreakPointLineOffsets(Set<Int>)
        case setCompletion(wantsVisible: Bool, aroundRange: Range<CodeStoragePosition>?)
    }
    public mutating func process(_ m:Message) {
        /// Clean up prior output.
        effects.removeAll()
        editing.storage.cleanTimeline()
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
        case let .setCompletion(mm):
            completionWindow.wantsVisible = mm.wantsVisible
            completionWindow.aroundRange = mm.aroundRange
        }
        /// Remove completion window if target range is invalid.
        /// This can happen as user delete existing characters included in the range.
        /// Hiding completion window is natural choice.
        
        if let r = completionWindow.aroundRange {
            if !editing.storage.isValidRange(r) {
                completionWindow.aroundRange = nil
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
        case .setCompletion: return true
        }
    }
    
    private mutating func processEdit(_ mm:CodeEditingMessage) {
        editing.apply(mm)
        let changes = editing.storage.timeline.points
        
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
                        source: editing.storage,
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
//            case let .placeText(s):
//                if [".", ":"].contains(s) {
//                    // Start completion.
//                    let p = editing.storage.caretPosition
//                    completionWindow = CompletionWindowState(aroundRange: p..<p)
//                }
            case let .processEditingCommand(mmmm):
                switch mmmm {
                case .cancelOperation:
                    completionWindow.aroundRange = nil
                    completionWindow.wantsVisible = false
                default: break
                }
            default: break
            }
        default: break
        }
        
        // Kill completion if caret goes out of its range.
        if let r = completionWindow.aroundRange {
            if !r.includedLineOffsetRange.contains(editing.storage.caretPosition.lineOffset) {
                completionWindow.aroundRange = nil
            }
            if editing.storage.caretPosition.characterUTF8Offset < r.lowerBound.characterUTF8Offset {
                completionWindow.aroundRange = nil
            }
        }
    }
    private mutating func processMenu(_ mm:CodeView.Note.MenuMessage) {
        switch mm {
        case .copy:
            let sss = editing.storage.lineContentsInCurrentSelection()
            let s = sss.joined(separator: "\n")
            effects.append(.replacePasteboardContent(s))
        case .cut:
            let sss = editing.storage.lineContentsInCurrentSelection()
            let s = sss.joined(separator: "\n")
            editing.storage.replaceCharactersInCurrentSelection(with: "")
            editing.recordTimePoint(as: .alienEditing(nameForMenu: "Cut"))
            editing.invalidate(.all)
            effects.append(.replacePasteboardContent(s))
        case let .paste(s):
            editing.storage.replaceCharactersInCurrentSelection(with: s)
            editing.recordTimePoint(as: .alienEditing(nameForMenu: "Paste"))
            editing.invalidate(.all)
        case .selectAll:
            editing.storage.selectAll()
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
            completionWindow.aroundRange = nil
            completionWindow.wantsVisible = false
        case .resignFirstResponder:
            completionWindow.aroundRange = nil
            completionWindow.wantsVisible = false
        case .resize:
            completionWindow.aroundRange = nil
            completionWindow.wantsVisible = false
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
