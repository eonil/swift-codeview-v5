//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/20/19.
//

import Foundation

/// Pre-built code-text, extra edit operations & break-point processing engine.
///
/// This is designed to provide minimum default code-text editing engine.
/// You can build more features around this.
///
public struct CodeManagement {
    public private(set) var editing = CodeEditing()
    /// This is supposed to stored less than hundred values.
    /// If this need to store more, this should use copy-friendly types.
    public private(set) var breakPointLineOffsets = Set<Int>()
    /// This is an output state.
    public private(set) var effects = [Effect]()
    public typealias Effect = CodeView.Control.Effect
    
    public init() {}
    public enum Message {
        case userInteraction(CodeUserMessage)
        case setBreakPointLineOffsets(Set<Int>)
    }
    /// Clears accumulated effects and results.
    /// This does NOT clear undo/redo history.
    /// At this moment, undo/redo history remains forever.
    public mutating func clean() {
        effects.removeAll()
        editing.storage.cleanTimeline()
    }
    /// This produces and accumulate effects and results.
    /// You can scan effects and result to process them.
    /// Call `clean()` to clear accumulated effects and results.
    public mutating func process(_ m:Message) {
        // Process.
        switch m {
        case let .userInteraction(mm):
            switch mm {
            case let .edit(mmm): processEdit(mmm)
            case let .menu(mmm): processMenu(mmm)
            }
        case let .setBreakPointLineOffsets(bps):
            breakPointLineOffsets = bps
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
