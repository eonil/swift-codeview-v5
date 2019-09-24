//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/19/19.
//

import Foundation
import AppKit

/// Performs layout/space based editing.
///
/// - This is default basic implementation of text editing engine.
/// - This can perform layout-based editing operations
///   - `CodeSourceEditing` can perform only line/character level editings.
/// - This is supposed to live momentarily only while you are applying an editing command.
///
/// This provides core text processing functionality.
///
public struct CodeEditing {
    /// Stored **parameters** to be supplied to each editing operations.
    public var config = CodeConfig()
    /// Timeline for undo/redo management.
    /// This timeline is based on changes in content (`CodeStorage`).
    /// Selection changes won't be regarded as changes and won't be recorded.
    /// This is different level of recording compared to `CodeSource.timeline`.
    /// `CodeSource.timeline` records each "replacement" editings.
    /// This timeline recording can contain multiple changes in `CodeSource.timeline` level.
    ///
    public private(set) var timeline = CodeTimeline()
    public internal(set) var storage = CodeStorage()
    public internal(set) var imeState = IMEState?.none
    
    /// Vertical caret movement between lines needs base X coordinate to align them on single line.
    /// Here the basis X cooridnate will be stored to provide aligned vertical movement.
    var moveVerticalAxisX = CGFloat?.none
    func findAxisXForVerticalMovement() -> CGFloat {
        let p = storage.caretPosition
        let line = storage.text.lines[storage.text.lines.startIndex + p.lineOffset]
        let charIndex = line.characters.utf8.index(line.characters.utf8.startIndex, offsetBy: p.characterUTF8Offset)
        let ss = line.characters[..<charIndex]
        let ctline = CTLine.make(with: ss, font: config.rendering.standardFont)
        let w = CTLineGetBoundsWithOptions(ctline, []).width
        return w
    }
    
    /// You call methods of `CodeEditor` to modify its state
    /// and check this flag portions of layout space that needs
    /// rendering.
    private(set) var invalidatedRegion = InvalidatedRegion.none
    typealias InvalidatedRegion = CodeEditingInvalidatedRegion
    mutating func invalidate(_ newRegion:InvalidatedRegion) {
        switch (invalidatedRegion, newRegion) {
        case (.none, .none): break
        case (.none, .some): invalidatedRegion = newRegion
        default: invalidatedRegion = .all
        }
    }
    
//    public private(set) var invalidatedRegion2 = invalidatedRegion2.none
//    public enum invalidatedRegion2 {
//        case none
//        /// For the case when user is editing only in single line.
//        case singleLine(lineAtOffset: Int)
//        case all
//    }
    
    // MARK: - External I/O
    typealias Message = CodeEditingMessage
    mutating func apply(_ c:Message) {
        invalidatedRegion = .none
        // Now each command processors should update
        // `invalidatedRegion` if needed.
        switch c {
        case let .reset(s):         reset(s)
        case let .edit(s, n):       edit(s, nameForMenu: n)
        case let .typing(n):        process(n)
        case let .mouse(n):
            switch n.kind {
            case .down:             processMouseDown(at: n.pointInBounds, in: n.bounds)
            case .dragged:          processMouseDragged(at: n.pointInBounds, in: n.bounds)
            case .up:               processMouseUp(at: n.pointInBounds, in: n.bounds)
            }
        }
    }
    mutating func applyStyle(_ s:CodeStyle, in range:Range<CodeStoragePosition>) {
        storage.setCharacterStyle(s, in: range)
    }
    
    // MARK: - Rendering
    /// Frame of currently typing area.
    /// This is for IME window placement.
    func typingFrame(in bounds:CGRect) -> CGRect {
        let layout = CodeLayout(
            config: config,
            storage: storage,
            imeState: imeState,
            boundingWidth: bounds.width)
        let f  = layout.frameOfSelectionInLine(
            at: storage.caretPosition.lineOffset)
        return f
    }
    private mutating func setNeedsRendering(in bounds:CGRect) {
        invalidatedRegion = .some(bounds: bounds)
    }
        
    /// Resets whole content at once with clearing all undo/redo stack.
    private mutating func reset(_ s:CodeStorage) {
        storage = s
        timeline = CodeTimeline(current: s)
        invalidatedRegion = .all
    }
    /// Pushes modified source.
    /// This command keeps undo/redo stack.
    private mutating func edit(_ s:CodeStorage, nameForMenu n:String) {
        storage = s
        unrecordAllInsignificantTimelinePoints()
        recordTimePoint(as: .alienEditing(nameForMenu: n))
        invalidatedRegion = .all
    }
    private mutating func process(_ n:TextTypingMessage) {
        switch n {
        case let .previewIncompleteText(content, selection):
            storage.replaceCharactersInCurrentSelection(with: "")
            imeState = IMEState(incompleteText: content, selectionInIncompleteText: selection)
        case let .placeText(s):
            imeState = nil
            storage.replaceCharactersInCurrentSelection(with: s)
            recordTimePoint(as: .typingCharacter)
        case let .processEditingCommand(cmd):
            switch cmd {
            case .moveLeft:
                moveVerticalAxisX = nil
                var c = storage.bestEffortCursorAtCaret
                c.moveOneCharToStart()
                storage.moveCaret(to: c.position)
                
            case .moveRight:
                moveVerticalAxisX = nil
                var c = storage.bestEffortCursorAtCaret
                c.moveOneCharToEnd()
                storage.moveCaret(to: c.position)

            case .moveLeftAndModifySelection:
                moveVerticalAxisX = nil
                var c = storage.bestEffortCursorAtCaret
                c.moveOneCharToStart()
                storage.moveCaretAndModifySelection(to: c.position)

            case .moveRightAndModifySelection:
                moveVerticalAxisX = nil
                var c = storage.bestEffortCursorAtCaret
                c.moveOneCharToEnd()
                storage.moveCaretAndModifySelection(to: c.position)
                
            case .moveWordLeft:
                moveVerticalAxisX = nil
                var c = storage.bestEffortCursorAtCaret
                c.inLineCharCursor.moveOneSubwordToStart() // Now we're using subword moving just for convenience.
                storage.moveCaret(to: c.position)
                
            case .moveWordLeftAndModifySelection:
                moveVerticalAxisX = nil
                var c = storage.bestEffortCursorAtCaret
                c.inLineCharCursor.moveOneSubwordToStart() // Now we're using subword moving just for convenience.
                storage.moveCaretAndModifySelection(to: c.position)
                
            case .moveWordRight:
                moveVerticalAxisX = nil
                var c = storage.bestEffortCursorAtCaret
                c.inLineCharCursor.moveOneSubwordToEnd() // Now we're using subword moving just for convenience.
                storage.moveCaret(to: c.position)
                
            case .moveWordRightAndModifySelection:
                moveVerticalAxisX = nil
                var c = storage.bestEffortCursorAtCaret
                c.inLineCharCursor.moveOneSubwordToEnd() // Now we're using subword moving just for convenience.
                storage.moveCaretAndModifySelection(to: c.position)

            case .moveBackward:
                moveVerticalAxisX = nil
                var c = storage.bestEffortCursorAtCaret
                c.inLineCharCursor.moveToStart()
                storage.moveCaret(to: c.position)
                
            case .moveBackwardAndModifySelection:
                moveVerticalAxisX = nil
                var c = storage.bestEffortCursorAtCaret
                c.inLineCharCursor.moveToStart()
                storage.moveCaretAndModifySelection(to: c.position)
                    
            case .moveForward:
                moveVerticalAxisX = nil
                var c = storage.bestEffortCursorAtCaret
                c.inLineCharCursor.moveToEnd()
                storage.moveCaret(to: c.position)
                
            case .moveForwardAndModifySelection:
                moveVerticalAxisX = nil
                var c = storage.bestEffortCursorAtCaret
                c.inLineCharCursor.moveToEnd()
                storage.moveCaretAndModifySelection(to: c.position)
                
            case .moveToLeftEndOfLine:
                moveVerticalAxisX = nil
                var c = storage.bestEffortCursorAtCaret
                c.inLineCharCursor.moveToStart()
                storage.moveCaret(to: c.position)
                
            case .moveToRightEndOfLine:
                moveVerticalAxisX = nil
                var c = storage.bestEffortCursorAtCaret
                c.inLineCharCursor.moveToEnd()
                storage.moveCaret(to: c.position)
                
            case .moveToLeftEndOfLineAndModifySelection:
                moveVerticalAxisX = nil
                var c = storage.bestEffortCursorAtCaret
                c.inLineCharCursor.moveToStart()
                storage.moveCaretAndModifySelection(to: c.position)
                
            case .moveToRightEndOfLineAndModifySelection:
                moveVerticalAxisX = nil
                var c = storage.bestEffortCursorAtCaret
                c.inLineCharCursor.moveToEnd()
                storage.moveCaretAndModifySelection(to: c.position)
                
            case .moveUp:
                moveVerticalAxisX = moveVerticalAxisX ?? findAxisXForVerticalMovement()
                guard let p = upLinePosition() else { return }
                storage.moveCaret(to: p)

            case .moveUpAndModifySelection:
                moveVerticalAxisX = moveVerticalAxisX ?? findAxisXForVerticalMovement()
                guard let p = upLinePosition() else { return }
                storage.moveCaretAndModifySelection(to: p)
                
            case .moveDown:
                moveVerticalAxisX = moveVerticalAxisX ?? findAxisXForVerticalMovement()
                guard let p = downLinePosition() else { return }
                storage.moveCaret(to: p)
                
            case .moveDownAndModifySelection:
                moveVerticalAxisX = moveVerticalAxisX ?? findAxisXForVerticalMovement()
                guard let p = downLinePosition() else { return }
                storage.moveCaretAndModifySelection(to: p)
            
            case .moveToBeginningOfParagraph:
                break
            case .moveToBeginningOfParagraphAndModifySelection:
                break
            case .moveToEndOfParagraph:
                break
            case .moveToEndOfParagraphAndModifySelection:
                break
            
            case .moveToBeginningOfDocument:
                moveVerticalAxisX = nil
                storage.moveCaret(to: storage.startPosition)
                
            case .moveToBeginningOfDocumentAndModifySelection:
                moveVerticalAxisX = nil
                storage.moveCaretAndModifySelection(to: storage.startPosition)
                
            case .moveToEndOfDocument:
                moveVerticalAxisX = nil
                storage.moveCaret(to: storage.endPosition)
                
            case .moveToEndOfDocumentAndModifySelection:
                moveVerticalAxisX = nil
                storage.moveCaretAndModifySelection(to: storage.endPosition)
                
            case .selectAll:
                moveVerticalAxisX = nil
                storage.selectAll()
                
            case .insertNewline:
                unrecordAllInsignificantTimelinePoints()
                recordTimePoint(as: .typingNewLine)
                moveVerticalAxisX = nil
                storage.replaceCharactersInCurrentSelection(with: "\n")
                
            case .insertTab:
                moveVerticalAxisX = nil
                let tabReplacement = config.editing.makeTabReplacement()
                storage.replaceCharactersInCurrentSelection(with: tabReplacement)
                recordTimePoint(as: .editingInteraction)

            case .insertBacktab:
                moveVerticalAxisX = nil
//                source.insertBacktab(config: config)
                assert(false, "Unimplemented yet.")
                
                
            case .deleteBackward:
                moveVerticalAxisX = nil
                if storage.selectionRange.isEmpty {
                    var c = storage.bestEffortCursorAtCaret
                    c.moveOneCharToStart()
                    storage.moveCaretAndModifySelection(to: c.position)
                }
                storage.replaceCharactersInCurrentSelection(with: "")
                recordTimePoint(as: .editingInteraction)
                
            case .deleteForward:
                moveVerticalAxisX = nil
                if storage.selectionRange.isEmpty {
                    var c = storage.bestEffortCursorAtCaret
                    c.moveOneCharToEnd()
                    storage.moveCaretAndModifySelection(to: c.position)
                }
                storage.replaceCharactersInCurrentSelection(with: "")
                recordTimePoint(as: .editingInteraction)
            
            case .deleteWordBackward:
                moveVerticalAxisX = nil
                if storage.selectionRange.isEmpty {
                    var cc = storage.bestEffortCursorAtCaret
                    cc.inLineCharCursor.moveOneWordToStart()
                    storage.moveCaretAndModifySelection(to: cc.position)
                }
                storage.replaceCharactersInCurrentSelection(with: "")
                recordTimePoint(as: .editingInteraction)
                
            case .deleteWordForward:
                moveVerticalAxisX = nil
                if storage.selectionRange.isEmpty {
                    var cc = storage.bestEffortCursorAtCaret
                    cc.inLineCharCursor.moveOneWordToEnd()
                    storage.moveCaretAndModifySelection(to: cc.position)
                }
                storage.replaceCharactersInCurrentSelection(with: "")
                recordTimePoint(as: .editingInteraction)
            
            case .deleteToBeginningOfLine:
                moveVerticalAxisX = nil
                var c = storage.bestEffortCursorAtCaret
                c.inLineCharCursor.moveToStart()
                storage.moveCaretAndModifySelection(to: c.position)
                storage.replaceCharactersInCurrentSelection(with: "")
                recordTimePoint(as: .editingInteraction)
                
            case .deleteToEndOfLine:
                moveVerticalAxisX = nil
                var c = storage.bestEffortCursorAtCaret
                c.inLineCharCursor.moveToEnd()
                storage.moveCaretAndModifySelection(to: c.position)
                storage.replaceCharactersInCurrentSelection(with: "")
                recordTimePoint(as: .editingInteraction)
                
            case .cancelOperation:
                break
            }
        }
        invalidatedRegion = .all
    }
    private func upLinePosition() -> CodeStoragePosition? {
        let p = storage.caretPosition
        guard 0 < p.lineOffset else { return nil }
        let upLineOffset = p.lineOffset - 1
        let upLine = storage.text.lines.atOffset(upLineOffset)
        let x = moveVerticalAxisX!
        let f = config.rendering.standardFont
        let charUTF8Offset = storage.characterUTF8Offset(at: x, in: upLine, with: f) ?? upLine.characters.utf8.count
        let newPosition = CodeStoragePosition(lineOffset: upLineOffset, characterUTF8Offset: charUTF8Offset)
        return newPosition
    }
    private func downLinePosition() -> CodeStoragePosition? {
        let p = storage.caretPosition
        guard p.lineOffset < storage.text.lines.count-1 else { return nil }
        let downLineOffset = p.lineOffset + 1
        let downLine = storage.text.lines.atOffset(downLineOffset)
        let x = moveVerticalAxisX!
        let f = config.rendering.standardFont
        let charUTF8Offset = storage.characterUTF8Offset(at: x, in: downLine, with: f) ?? downLine.characters.utf8.count
        let newPosition = CodeStoragePosition(lineOffset: downLineOffset, characterUTF8Offset: charUTF8Offset)
        return newPosition
    }
    
    private mutating func processMouseDown(at point:CGPoint, in bounds:CGRect) {
        let layout = makeLayout(in: bounds.width)
        if point.x < layout.config.rendering.breakpointWidth {
        }
        else {
            let p = layout.clampingPosition(at: point)
            storage.caretPosition = p
            storage.selectionRange = p..<p
            storage.selectionAnchorPosition = p
        }
        setNeedsRendering(in: bounds)
    }
    private mutating func processMouseDragged(at point:CGPoint, in bounds:CGRect) {
        // Update caret and selection by mouse dragging.
        let layout = CodeLayout(config: config, storage: storage, imeState: imeState, boundingWidth: bounds.width)
        let p = layout.clampingPosition(at: point)
        let oldSource = storage
        storage.modifySelectionWithAnchor(to: p)
        // Render only if caret or selection has been changed.
        let isRenderingInvalidated
            =  storage.caretPosition != oldSource.caretPosition
            || storage.selectionRange != oldSource.selectionRange
        if isRenderingInvalidated {
            setNeedsRendering(in: bounds)
        }
    }
    private mutating func processMouseUp(at point:CGPoint, in bounds:CGRect) {
        storage.selectionAnchorPosition = nil
    }
    
//    mutating func copy() -> String {
//        invalidatedRegion = .none
//        let sss = source.lineContentsInCurrentSelection()
//        let s = sss.joined(separator: "\n")
//        return s
//    }
//    mutating func replace(_ s:String, nameForMenu n:String) {
//        source.replaceCharactersInCurrentSelection(with: s)
//        state.recordTimePoint(as: .alienEditing(nameForMenu: n))
//        render()
//    }
}
extension CodeEditing {
    // MARK: - Undo/Redo Support
    mutating func undoInTimeline() {
        timeline.undo()
        storage = timeline.currentPoint.snapshot
    }
    mutating func redoInTimeline() {
        timeline.redo()
        storage = timeline.currentPoint.snapshot
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
    mutating func unrecordAllInsignificantTimelinePoints() {
        // Replace any existing small typing (character-level) actions
        // with single large typing action on new-line.
        let s = storage
        while !timeline.undoablePoints.isEmpty && !timeline.currentPoint.kind.isSignificant {
            undoInTimeline()
        }
        storage = s
    }
    /// Records a new undo point.
    ///
    /// You can treat this as a save-point. Calling undo rolls state back to latest save-point.
    /// Therefore, you are supposed to call this before making new change.
    ///
    mutating func recordTimePoint(as kind: CodeOperationKind) {
        /// Clean up its timeline before record.
        /// So undo/redo will produce source snapshot with no storage-level timeline.
        /// So it can represent snapshot replacement.
        var sourceToRecord = storage
        sourceToRecord.cleanTimeline()
        timeline.record(sourceToRecord, as: kind)
    }
}
