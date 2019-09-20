//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/19/19.
//

import Foundation
import AppKit

/// Represents an GUI level editing transaction of`CodeState`.
///
/// - This can perform layout-based editing operations
///   - `CodeSourceEditing` can perform only line/character level editings.
/// - This is supposed to live momentarily only while you are applying an editing command.
///
/// This provides core text processing functionality.
///
struct CodeEditing {
    /// Stored **parameters** to be supplied to each editing operations.
    var config = CodeConfig()
    private(set) var state = CodeState()
    /// You call methods of `CodeEditor` to modify its state
    /// and check this flag portions of layout space that needs
    /// rendering.
    private(set) var invalidatedRegion = InvalidatedRegion.none
    typealias InvalidatedRegion = CodeEditingInvalidatedRegion
    
    init(config x: CodeConfig, state s:CodeState) {
        config = x
        state = s
    }
    
    // MARK: - External I/O
    typealias Message = CodeEditingMessage
    mutating func apply(_ c:Message) {
        invalidatedRegion = .none
        // Now each command processors should update
        // `invalidatedRegion` if needed.
        switch c {
        case let .reset(s):         reset(s)
        case let .edit(s, n):       edit(s, nameForMenu: n)
        case let .typing(n):    process(n)
        case let .mouse(n):
            switch n.kind {
            case .down:             processMouseDown(at: n.pointInBounds, in: n.bounds)
            case .dragged:          processMouseDragged(at: n.pointInBounds, in: n.bounds)
            case .up:               processMouseUp(at: n.pointInBounds, in: n.bounds)
            }
        }
    }
    
    // MARK: - Quick Access
    private(set) var timeline: CodeTimeline {
        get { return state.timeline }
        set(x) { state.timeline = x }
    }
    private(set) var source: CodeSource {
        get { return state.source }
        set(x) { state.source = x }
    }
    private(set) var imeState: IMEState? {
        get { return state.imeState }
        set(x) { state.imeState = x }
    }
    private var moveVerticalAxisX: CGFloat? {
        get { return state.moveVerticalAxisX }
        set(x) { state.moveVerticalAxisX = x }
    }
    private func findAxisXForVerticalMovement() -> CGFloat {
        return state.findAxisXForVerticalMovement(config: config)
    }
    
    // MARK: - Rendering
    /// Frame of currently typing area.
    /// This is for IME window placement.
    func typingFrame(in bounds:CGRect) -> CGRect {
        let layout = CodeLayout(
            config: config,
            source: source,
            imeState: imeState,
            boundingWidth: bounds.width)
        let f  = layout.frameOfSelectionInLine(
            at: source.caretPosition.lineOffset)
        return f
    }
    private mutating func render() {
        invalidatedRegion = .all
    }
    private mutating func setNeedsRendering(in bounds:CGRect) {
        invalidatedRegion = .some(bounds: bounds)
    }
        
    /// Resets whole content at once with clearing all undo/redo stack.
    private mutating func reset(_ s:CodeSource) {
        source = s
        timeline = CodeTimeline(current: s)
        render()
    }
    /// Pushes modified source.
    /// This command keeps undo/redo stack.
    private mutating func edit(_ s:CodeSource, nameForMenu n:String) {
        source = s
        state.unrecordAllInsignificantTimelinePoints()
        state.recordTimePoint(as: .alienEditing(nameForMenu: n))
        render()
    }
    private mutating func process(_ n:TextTypingMessage) {
        switch n {
        case let .previewIncompleteText(content, selection):
            source.replaceCharactersInCurrentSelection(with: "")
            imeState = IMEState(incompleteText: content, selectionInIncompleteText: selection)
        case let .placeText(s):
            imeState = nil
            source.replaceCharactersInCurrentSelection(with: s)
            state.recordTimePoint(as: .typingCharacter)
        case let .processEditingCommand(cmd):
            switch cmd {
            case .moveLeft:
                moveVerticalAxisX = nil
                source.moveCaret(to: source.leftCharacterCaretPosition())
                
            case .moveRight:
                moveVerticalAxisX = nil
                source.moveCaret(to: source.rightCharacterCaretPosition())

            case .moveLeftAndModifySelection:
                moveVerticalAxisX = nil
                source.moveCaretAndModifySelection(to: source.leftCharacterCaretPosition())

            case .moveRightAndModifySelection:
                moveVerticalAxisX = nil
                source.moveCaretAndModifySelection(to: source.rightCharacterCaretPosition())
                
            case .moveToLeftEndOfLine:
                moveVerticalAxisX = nil
                let oldPosition = source.caretPosition
                let newPosition = source.leftEndPositionOfLine1(at: oldPosition.lineOffset)
                source.moveCaret(to: newPosition)
                
            case .moveToRightEndOfLine:
                moveVerticalAxisX = nil
                let oldPosition = source.caretPosition
                let newPosition = source.rightEndPositionOfLine1(at: oldPosition.lineOffset)
                source.moveCaret(to: newPosition)
                
            case .moveToLeftEndOfLineAndModifySelection:
                moveVerticalAxisX = nil
                let oldPosition = source.caretPosition
                let newPosition = source.leftEndPositionOfLine1(at: oldPosition.lineOffset)
                source.moveCaretAndModifySelection(to: newPosition)
                
            case .moveToRightEndOfLineAndModifySelection:
                moveVerticalAxisX = nil
                let oldPosition = source.caretPosition
                let newPosition = source.rightEndPositionOfLine1(at: oldPosition.lineOffset)
                source.moveCaretAndModifySelection(to: newPosition)
                
            case .moveUp:
                moveVerticalAxisX = moveVerticalAxisX ?? findAxisXForVerticalMovement()
                guard let p = upLinePosition() else { return }
                source.moveCaret(to: p)
                
            case .moveDown:
                moveVerticalAxisX = moveVerticalAxisX ?? findAxisXForVerticalMovement()
                guard let p = downLinePosition() else { return }
                source.moveCaret(to: p)
                
            case .moveUpAndModifySelection:
                moveVerticalAxisX = moveVerticalAxisX ?? findAxisXForVerticalMovement()
                guard let p = upLinePosition() else { return }
                source.moveCaretAndModifySelection(to: p)
                
            case .moveDownAndModifySelection:
                moveVerticalAxisX = moveVerticalAxisX ?? findAxisXForVerticalMovement()
                guard let p = downLinePosition() else { return }
                source.moveCaretAndModifySelection(to: p)
                
            case .moveToBeginningOfDocument:
                moveVerticalAxisX = nil
                source.moveCaret(to: source.startPosition)
                
            case .moveToBeginningOfDocumentAndModifySelection:
                moveVerticalAxisX = nil
                source.moveCaretAndModifySelection(to: source.startPosition)
                
            case .moveToEndOfDocument:
                moveVerticalAxisX = nil
                source.moveCaret(to: source.endPosition)
                
            case .moveToEndOfDocumentAndModifySelection:
                moveVerticalAxisX = nil
                source.moveCaretAndModifySelection(to: source.endPosition)
                
            case .selectAll:
                moveVerticalAxisX = nil
                source.selectAll()
                
            case .insertNewline:
                state.unrecordAllInsignificantTimelinePoints()
                state.recordTimePoint(as: .typingNewLine)
                moveVerticalAxisX = nil
                source.insertNewLine(config: config)
                
            case .insertTab:
                moveVerticalAxisX = nil
                let tabReplacement = config.editing.makeTabReplacement()
                source.replaceCharactersInCurrentSelection(with: tabReplacement)

            case .insertBacktab:
                moveVerticalAxisX = nil
//                source.insertBacktab(config: config)
                assert(false, "Unimplemented yet.")
                
            case .deleteForward:
                moveVerticalAxisX = nil
                if source.selectionRange.isEmpty {
                    source.moveCaretAndModifySelection(to: source.rightCharacterCaretPosition())
                }
                source.replaceCharactersInCurrentSelection(with: "")
                
            case .deleteBackward:
                moveVerticalAxisX = nil
                if source.selectionRange.isEmpty {
                    source.moveCaretAndModifySelection(to: source.leftCharacterCaretPosition())
                }
                source.replaceCharactersInCurrentSelection(with: "")
                
            case .deleteToBeginningOfLine:
                moveVerticalAxisX = nil
                source.moveCaretAndModifySelection(to: source.leftEndPositionOfLine1(at: source.caretPosition.lineOffset))
                source.replaceCharactersInCurrentSelection(with: "")
                
            case .deleteToEndOfLine:
                moveVerticalAxisX = nil
                source.moveCaretAndModifySelection(to: source.rightEndPositionOfLine1(at: source.caretPosition.lineOffset))
                source.replaceCharactersInCurrentSelection(with: "")
            case .cancelOperation:
                break
            }
        }
        render()
    }
    private func upLinePosition() -> CodeStoragePosition? {
        let p = source.caretPosition
        guard 0 < p.lineOffset else { return nil }
        let upLineOffset = p.lineOffset - 1
        let upLine = source.storage.lines.atOffset(upLineOffset)
        let x = moveVerticalAxisX!
        let f = config.rendering.font
        let charUTF8Offset = source.characterUTF8Offset(at: x, in: upLine, with: f) ?? upLine.content.utf8.count
        let newPosition = CodeStoragePosition(lineOffset: upLineOffset, characterUTF8Offset: charUTF8Offset)
        return newPosition
    }
    private func downLinePosition() -> CodeStoragePosition? {
        let p = source.caretPosition
        guard p.lineOffset < source.storage.lines.count-1 else { return nil }
        let downLineOffset = p.lineOffset + 1
        let downLine = source.storage.lines.atOffset(downLineOffset)
        let x = moveVerticalAxisX!
        let f = config.rendering.font
        let charUTF8Offset = source.characterUTF8Offset(at: x, in: downLine, with: f) ?? downLine.content.utf8.count
        let newPosition = CodeStoragePosition(lineOffset: downLineOffset, characterUTF8Offset: charUTF8Offset)
        return newPosition
    }
    
    private mutating func processMouseDown(at point:CGPoint, in bounds:CGRect) {
        let layout = CodeLayout(config: config, source: source, imeState: imeState, boundingWidth: bounds.width)
        if point.x < layout.config.rendering.breakpointWidth {
            let lineOffset = layout.clampingLineOffset(at: point.y)
            // Toggle breakpoint.
            source.toggleBreakPoint(at: lineOffset)
        }
        else {
            let p = layout.clampingPosition(at: point)
            source.caretPosition = p
            source.selectionRange = p..<p
            source.selectionAnchorPosition = p
        }
        setNeedsRendering(in: bounds)
    }
    private mutating func processMouseDragged(at point:CGPoint, in bounds:CGRect) {
        // Update caret and selection by mouse dragging.
        let layout = CodeLayout(config: config, source: source, imeState: imeState, boundingWidth: bounds.width)
        let p = layout.clampingPosition(at: point)
        let oldSource = source
        source.modifySelectionWithAnchor(to: p)
        // Render only if caret or selection has been changed.
        let isRenderingInvalidated
            =  source.caretPosition != oldSource.caretPosition
            || source.selectionRange != oldSource.selectionRange
        if isRenderingInvalidated {
            setNeedsRendering(in: bounds)
        }
    }
    private mutating func processMouseUp(at point:CGPoint, in bounds:CGRect) {
        source.selectionAnchorPosition = nil
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
