//
//  CodeEditingState.swift
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
public struct CodeState {
    var timeline = CodeTimeline()
    public internal(set) var source = CodeSource()
    public internal(set) var imeState = IMEState?.none
    
    /// Vertical caret movement between lines needs base X coordinate to align them on single line.
    /// Here the basis X cooridnate will be stored to provide aligned vertical movement.
    var moveVerticalAxisX = CGFloat?.none
    func findAxisXForVerticalMovement(config: CodeConfig) -> CGFloat {
        let p = source.caretPosition
        let line = source.storage.lines[source.storage.lines.startIndex + p.lineOffset]
        let charIndex = line.content.utf8.index(line.content.utf8.startIndex, offsetBy: p.characterUTF8Offset)
        let ss = line.content[..<charIndex]
        let ctline = CTLine.make(with: ss, font: config.rendering.font)
        let w = CTLineGetBoundsWithOptions(ctline, []).width
        return w
    }
    
    /// Frame of currently typing area.
    /// This is for IME window placement.
    func typingFrame(config: CodeConfig, in bounds:CGRect) -> CGRect {
        let layout = CodeLayout(
            config: config,
            source: source,
            imeState: imeState,
            boundingWidth: bounds.width)
        let f  = layout.frameOfSelectionInLine(
            at: source.caretPosition.lineOffset)
        return f
    }
}
extension CodeState {
    // MARK: - Undo/Redo Support
    mutating func undoInTimeline() {
        timeline.undo()
        source = timeline.currentPoint.snapshot
    }
    mutating func redoInTimeline() {
        timeline.redo()
        source = timeline.currentPoint.snapshot
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
    mutating func recordTimePoint(as kind: CodeOperationKind) {
        /// Clean up its timeline before record.
        /// So undo/redo will produce source snapshot with no storage-level timeline.
        /// So it can represent snapshot replacement.
        var sourceToRecord = source
        sourceToRecord.cleanTimeline()
        timeline.record(sourceToRecord, as: kind)
    }
}
