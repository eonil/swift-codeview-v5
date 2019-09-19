//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/19/19.
//

import Foundation
import AppKit

/// Manages all about code editing.
/// This manages full timeline & IME.
///
/// This also can manage layout.
/// Layout space starts from (0,0) and increases positively to right and bottom direction.
///
struct CodeEditor {
    private var config = CodeSourceConfig()
    private var timeline = CodeTimeline()
    private var editor = CodeSource()
    private var imeState = IMEState?.none
    
    /// Vertical caret movement between lines needs base X coordinate to align them on single line.
    /// Here the basis X cooridnate will be stored to provide aligned vertical movement.
    private var moveVerticalAxisX = CGFloat?.none
    private func findAxisXForVerticalMovement() -> CGFloat {
        let p = editor.caretPosition
        let line = editor.storage.lines[p.lineIndex]
        let s = line[..<p.characterIndex]
        let ctline = CTLine.make(with: s, font: editor.config.rendering.font)
        let w = CTLineGetBoundsWithOptions(ctline, []).width
        return w
    }
    // MARK: - Undo/Redo Support
    private mutating func undoInTimeline() {
        timeline.undo()
        editor = timeline.currentPoint.snapshot
        render()
    }
    private mutating func redoInTimeline() {
        timeline.redo()
        editor = timeline.currentPoint.snapshot
        render()
    }
    /// Unrecords small changed made by typing or other actions.
    ///
    /// Once end-user finished typing a line,
    /// end-user would like to undo/redo that line at once instead of undo/redo
    /// them for each characters one by one.
    /// To provide such behavior, we need to "unrecord" existing small changes
    /// made by typing small units. This method does that unrecording.
    /// You are supposed to record a new snapshot point to make
    /// large unit change.
    private mutating func unrecordAllInsignificantTimelinePoints() {
        // Replace any existing small typing (character-level) actions
        // with single large typing action on new-line.
        let s = editor
        while !timeline.undoablePoints.isEmpty && !timeline.currentPoint.kind.isSignificant {
            undoInTimeline()
        }
        editor = s
    }
    /// Records a new undo point.
    ///
    /// You can treat this as a save-point. Calling undo rolls state back to latest save-point.
    /// Therefore, you are supposed to call this before making new change.
    ///
    private mutating func recordTimePoint(as kind: CodeOperationKind) {
        timeline.record(editor, as: kind)
    }
    
    // MARK: - Rendering
    private func render() {
        fatalError()
    }
    private func setNeedsRendering(in bounds:CGRect) {
        fatalError()
    }
    
    // MARK: - External I/O
    init() {
        config.rendering.font = NSFont(name: "SF Mono", size: NSFont.systemFontSize) ?? config.rendering.font
        config.rendering.lineNumberFont = NSFont(name: "SF Compact", size: NSFont.smallSystemFontSize) ?? config.rendering.lineNumberFont
    }
    /// Resets whole content at once with clearing all undo/redo stack.
    mutating func reset(_ s:CodeSource) {
        editor = s
        timeline = CodeTimeline(current: s)
        render()
    }
    /// Pushes modified source.
    /// This command keeps undo/redo stack.
    mutating func edit(_ s:CodeSource, nameForMenu n:String) {
        editor = s
        unrecordAllInsignificantTimelinePoints()
        recordTimePoint(as: .alienEditing(nameForMenu: n))
        render()
    }
    mutating func process(_ n:TextTypingNote) {
        switch n {
        case let .previewIncompleteText(content, selection):
            editor.replaceCharactersInCurrentSelection(with: "")
            imeState = IMEState(incompleteText: content, selectionInIncompleteText: selection)
        case let .placeText(s):
            imeState = nil
            editor.replaceCharactersInCurrentSelection(with: s)
            recordTimePoint(as: .typingCharacter)
        case let .processEditingCommand(cmd):
            switch cmd {
            case .moveLeft:
                moveVerticalAxisX = nil
                editor.moveLeft()
            case .moveRight:
                moveVerticalAxisX = nil
                editor.moveRight()
            case .moveLeftAndModifySelection:
                moveVerticalAxisX = nil
                editor.moveLeftAndModifySelection()
            case .moveRightAndModifySelection:
                moveVerticalAxisX = nil
                editor.moveRightAndModifySelection()
            case .moveToLeftEndOfLine:
                moveVerticalAxisX = nil
                editor.moveToLeftEndOfLine()
            case .moveToRightEndOfLine:
                moveVerticalAxisX = nil
                editor.moveToRightEndOfLine()
            case .moveToLeftEndOfLineAndModifySelection:
                moveVerticalAxisX = nil
                editor.moveToLeftEndOfLineAndModifySelection()
            case .moveToRightEndOfLineAndModifySelection:
                moveVerticalAxisX = nil
                editor.moveToRightEndOfLineAndModifySelection()
            case .moveUp:
                moveVerticalAxisX = moveVerticalAxisX ?? findAxisXForVerticalMovement()
                editor.moveUp(font: editor.config.rendering.font, at: moveVerticalAxisX!)
            case .moveDown:
                moveVerticalAxisX = moveVerticalAxisX ?? findAxisXForVerticalMovement()
                editor.moveDown(font: editor.config.rendering.font, at: moveVerticalAxisX!)
            case .moveUpAndModifySelection:
                moveVerticalAxisX = moveVerticalAxisX ?? findAxisXForVerticalMovement()
                editor.moveUpAndModifySelection(font: editor.config.rendering.font, at: moveVerticalAxisX!)
            case .moveDownAndModifySelection:
                moveVerticalAxisX = moveVerticalAxisX ?? findAxisXForVerticalMovement()
                editor.moveDownAndModifySelection(font: editor.config.rendering.font, at: moveVerticalAxisX!)
            case .moveToBeginningOfDocument:
                editor.moveToBeginningOfDocument()
            case .moveToBeginningOfDocumentAndModifySelection:
                moveVerticalAxisX = nil
                editor.moveToBeginningOfDocumentAndModifySelection()
            case .moveToEndOfDocument:
                moveVerticalAxisX = nil
                editor.moveToEndOfDocument()
            case .moveToEndOfDocumentAndModifySelection:
                moveVerticalAxisX = nil
                editor.moveToEndOfDocumentAndModifySelection()
            case .selectAll:
                moveVerticalAxisX = nil
                editor.selectAll()
            case .insertNewline:
                unrecordAllInsignificantTimelinePoints()
                recordTimePoint(as: .typingNewLine)
                moveVerticalAxisX = nil
                editor.insertNewLine()
            case .insertTab:
                moveVerticalAxisX = nil
                editor.insertTab()
            case .insertBacktab:
                moveVerticalAxisX = nil
                editor.insertBacktab()
            case .deleteForward:
                moveVerticalAxisX = nil
                editor.deleteForward()
            case .deleteBackward:
                moveVerticalAxisX = nil
                editor.deleteBackward()
            case .deleteToBeginningOfLine:
                moveVerticalAxisX = nil
                editor.deleteToBeginningOfLine()
            case .deleteToEndOfLine:
                moveVerticalAxisX = nil
                editor.deleteToEndOfLine()
            case .cancelOperation:
                break
            }
        }
        render()
    }
    mutating func processMouseDown(at point:CGPoint, in bounds:CGRect) {
        let layout = CodeLayout(config: config, source: editor, imeState: imeState, boundingWidth: bounds.width)
        if point.x < layout.config.rendering.breakpointWidth {
            let i = layout.clampingLineIndex(at: point.y)
            // Toggle breakpoint.
            editor.toggleBreakPoint(at: i)
        }
        else {
            let p = layout.clampingPosition(at: point)
            editor.caretPosition = p
            editor.selectionRange = p..<p
            editor.selectionAnchorPosition = p
        }
        setNeedsRendering(in: bounds)
    }
    mutating func processMouseDragged(at point:CGPoint, in bounds:CGRect) {
        // Update caret and selection by mouse dragging.
        let layout = CodeLayout(config: config, source: editor, imeState: imeState, boundingWidth: bounds.width)
        let p = layout.clampingPosition(at: point)
        let oldSource = editor
        editor.modifySelectionWithAnchor(to: p)
        // Render only if caret or selection has been changed.
        let isRenderingInvalidated
            =  editor.caretPosition != oldSource.caretPosition
            || editor.selectionRange != oldSource.selectionRange
        if isRenderingInvalidated {
            setNeedsRendering(in: bounds)
        }
    }
    mutating func processMouseUp(at point:CGPoint, in bounds:CGRect) {
        editor.selectionAnchorPosition = nil
    }
    mutating func selectAll() {
        editor.selectAll()
        render()
    }
    mutating func copy() -> String {
        let sss = editor.lineContentsInCurrentSelection()
        let s = sss.joined(separator: "\n")
        return s
    }
    mutating func cut() -> String {
        let sss = editor.lineContentsInCurrentSelection()
        let s = sss.joined(separator: "\n")
        editor.replaceCharactersInCurrentSelection(with: "")
        render()
        return s
    }
    mutating func paste(_ s:String) {
        editor.replaceCharactersInCurrentSelection(with: s)
        recordTimePoint(as: .alienEditing(nameForMenu: "Paste"))
        render()
    }
//    public var note: ((Note) -> Void)?
//    public enum Note {
//        /// Notifies view conetnt has been updated by editing action.
//        /// These are actiona that create new history point in timeline.
//        /// Editing of replacing characters in selected range.
//        /// `storageBeforeReplacement.selectedRange` is the range gets replaced.
//        /// - Note:
//        ///     `CodeSource.version` can be rolled back to past one if undo has been performed.
//        case editing(Editing)
//        public struct Editing {
//            public var replacementContent: String
//            public var sourceBeforeReplacement: CodeSource
//            public var sourceAfterReplacement: CodeSource
//        }
//        /// Notifies silent replacement of source.
//        /// These are all non-editing action based replacement.
//        /// As there's no editing action, we cannot notify as editing
//        /// but they still should be notified.
//        /// - Note:
//        ///     `CodeSource.version` can be rolled back to past one if undo has been performed.
//        case replaceAllSilently(CodeSource)
//        /// Unhandled `cancelOperation` selector command.
//        /// This command is supposed to be handled by IME at first,
//        /// but when IME is inactive, this is no-op.
//        /// This is sent for any interested containers.
//        case cancelOperation
//    }

}
