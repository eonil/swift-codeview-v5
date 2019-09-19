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
struct CodeEditing {
    /// Stored **parameters** to be supplied to each editing operations.
    var config = CodeConfig()
    private(set) var state = CodeState()
    /// You call methods of `CodeEditor` to modify its state
    /// and check this flag portions of layout space that needs
    /// rendering.
    private(set) var invalidatedRegion = InvalidatedRegion.none
    enum InvalidatedRegion {
        case none
        case some(bounds: CGRect)
        case all
    }
    init(config x: CodeConfig, state s:CodeState) {
        config = x
        state = s
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
    
    // MARK: - Undo/Redo Support
    private mutating func undoInTimeline() {
        timeline.undo()
        source = timeline.currentPoint.snapshot
        render()
    }
    private mutating func redoInTimeline() {
        timeline.redo()
        source = timeline.currentPoint.snapshot
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
        let s = source
        while !timeline.undoablePoints.isEmpty && !timeline.currentPoint.kind.isSignificant {
            undoInTimeline()
        }
        source = s
    }
    /// Records a new undo point.
    ///
    /// You can treat this as a save-point. Calling undo rolls state back to latest save-point.
    /// Therefore, you are supposed to call this before making new change.
    ///
    private mutating func recordTimePoint(as kind: CodeOperationKind) {
        /// Clean up its timeline before record.
        /// So undo/redo will produce source snapshot with no storage-level timeline.
        /// So it can represent snapshot replacement.
        var sourceToRecord = source
        sourceToRecord.cleanTimeline()
        timeline.record(sourceToRecord, as: kind)
    }
    
    // MARK: - Rendering
    private mutating func render() {
        invalidatedRegion = .all
    }
    private mutating func setNeedsRendering(in bounds:CGRect) {
        invalidatedRegion = .some(bounds: bounds)
    }
    
    // MARK: - External I/O
    /// Frame of currently typing area.
    /// This is for IME window placement.
    func typingFrame(in bounds:CGRect) -> CGRect {
        let layout = CodeLayout(
            config: config,
            source: source,
            imeState: imeState,
            boundingWidth: bounds.width)
        let f  = layout.frameOfSelectionInLine(
            at: source.caretPosition.lineIndex)
        return f
    }
    enum Control {
        case reset(CodeSource)
        case edit(CodeSource, nameForMenu: String)
        case textTyping(TextTypingNote)
        case mouse(MouseNote)
        struct MouseNote {
            var kind: Kind
            var pointInBounds: CGPoint
            var bounds: CGRect
            enum Kind {
                case down, dragged, up
            }
        }
        case selectAll
        case undo
        case redo
    }
    mutating func process(_ c:Control) {
        invalidatedRegion = .none
        // Now each command processors should update
        // `invalidatedRegion` if needed.
        switch c {
        case let .reset(s):         reset(s)
        case let .edit(s, n):       edit(s, nameForMenu: n)
        case let .textTyping(n):    process(n)
        case let .mouse(n):
            switch n.kind {
            case .down:             processMouseDown(at: n.pointInBounds, in: n.bounds)
            case .dragged:          processMouseDragged(at: n.pointInBounds, in: n.bounds)
            case .up:               processMouseUp(at: n.pointInBounds, in: n.bounds)
            }
        case .selectAll:            selectAll()
        case .undo:                 undo()
        case .redo:                 redo()
        }
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
        unrecordAllInsignificantTimelinePoints()
        recordTimePoint(as: .alienEditing(nameForMenu: n))
        render()
    }
    private mutating func process(_ n:TextTypingNote) {
        switch n {
        case let .previewIncompleteText(content, selection):
            source.replaceCharactersInCurrentSelection(with: "")
            imeState = IMEState(incompleteText: content, selectionInIncompleteText: selection)
        case let .placeText(s):
            imeState = nil
            source.replaceCharactersInCurrentSelection(with: s)
            recordTimePoint(as: .typingCharacter)
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
                let newPosition = source.leftEndPositionOfLine(at: oldPosition.lineIndex)
                source.moveCaret(to: newPosition)
                
            case .moveToRightEndOfLine:
                moveVerticalAxisX = nil
                let oldPosition = source.caretPosition
                let newPosition = source.rightEndPositionOfLine(at: oldPosition.lineIndex)
                source.moveCaret(to: newPosition)
                
            case .moveToLeftEndOfLineAndModifySelection:
                moveVerticalAxisX = nil
                let oldPosition = source.caretPosition
                let newPosition = source.leftEndPositionOfLine(at: oldPosition.lineIndex)
                source.moveCaretAndModifySelection(to: newPosition)
                
            case .moveToRightEndOfLineAndModifySelection:
                moveVerticalAxisX = nil
                let oldPosition = source.caretPosition
                let newPosition = source.rightEndPositionOfLine(at: oldPosition.lineIndex)
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
                unrecordAllInsignificantTimelinePoints()
                recordTimePoint(as: .typingNewLine)
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
                source.moveCaretAndModifySelection(to: source.rightCharacterCaretPosition())
                source.replaceCharactersInCurrentSelection(with: "")
                
            case .deleteBackward:
                moveVerticalAxisX = nil
                source.moveCaretAndModifySelection(to: source.leftCharacterCaretPosition())
                source.replaceCharactersInCurrentSelection(with: "")
                
            case .deleteToBeginningOfLine:
                moveVerticalAxisX = nil
                source.moveCaretAndModifySelection(to: source.leftEndPositionOfLine(at: source.caretPosition.lineIndex))
                source.replaceCharactersInCurrentSelection(with: "")
                
            case .deleteToEndOfLine:
                moveVerticalAxisX = nil
                source.moveCaretAndModifySelection(to: source.rightEndPositionOfLine(at: source.caretPosition.lineIndex))
                source.replaceCharactersInCurrentSelection(with: "")
            case .cancelOperation:
                break
            }
        }
        render()
    }
    private func upLinePosition() -> CodeStoragePosition? {
        let p = source.caretPosition
        guard 0 < p.lineIndex else { return nil }
        let li = p.lineIndex - 1
        let line = source.storage.lines[li]
        let x = moveVerticalAxisX!
        let f = config.rendering.font
        let ci = source.characterIndex(at: x, in: line, with: f) ?? line.endIndex
        let q = CodeStoragePosition(lineIndex: li, characterIndex: ci)
        return q
    }
    private func downLinePosition() -> CodeStoragePosition? {
        let p = source.caretPosition
        guard p.lineIndex < source.storage.lines.count-1 else { return nil }
        let li = p.lineIndex + 1
        let line = source.storage.lines[li]
        let x = moveVerticalAxisX!
        let f = config.rendering.font
        let ci = source.characterIndex(at: x, in: line, with: f) ?? line.endIndex
        let q = CodeStoragePosition(lineIndex: li, characterIndex: ci)
        return q
    }
    
    private mutating func processMouseDown(at point:CGPoint, in bounds:CGRect) {
        let layout = CodeLayout(config: config, source: source, imeState: imeState, boundingWidth: bounds.width)
        if point.x < layout.config.rendering.breakpointWidth {
            let i = layout.clampingLineIndex(at: point.y)
            // Toggle breakpoint.
            source.toggleBreakPoint(at: i)
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
    private mutating func selectAll() {
        source.selectAll()
        render()
    }
    private mutating func undo() {
        undoInTimeline()
        render()
    }
    private mutating func redo() {
        redoInTimeline()
        render()
    }
    
    mutating func copy() -> String {
        invalidatedRegion = .none
        let sss = source.lineContentsInCurrentSelection()
        let s = sss.joined(separator: "\n")
        return s
    }
    mutating func cut() -> String {
        let sss = source.lineContentsInCurrentSelection()
        let s = sss.joined(separator: "\n")
        source.replaceCharactersInCurrentSelection(with: "")
        recordTimePoint(as: .alienEditing(nameForMenu: "Cut"))
        render()
        return s
    }
    mutating func paste(_ s:String) {
        source.replaceCharactersInCurrentSelection(with: s)
        recordTimePoint(as: .alienEditing(nameForMenu: "Paste"))
        render()
    }
}