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
    public private(set) var annotation = CodeAnnotation()
    /// This is an output state.
    public private(set) var effects = [Effect]()
    public typealias Effect = CodeView.Control.Effect
    
    public init() {}
    public enum Message {
        case performEditing(CodeEditingMessage)
        /// This does not modify textual content,
        /// therefore does not make any timeline entries.
        /// No new undo/redo nor change-sets.
        case setStyle(CodeStyle, in: Range<CodeStoragePosition>)
        case setAnnotation(CodeAnnotation)
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
        case let .performEditing(mm):   processEdit(mm)
        case let .setStyle(s, range):   editing.applyStyle(s, in: range)
        case let .setAnnotation(anno):  annotation = anno
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
                // Move or kill break-points.
                annotation.breakPoints = Set(annotation.breakPoints.compactMap({ i in
                    if i <= rangeToReplace.lowerBound.lineOffset {
                        return i
                    }
                    else {
                        let k = i + -removeLineCount + newLineCharCount
                        return k <= rangeToReplace.lowerBound.lineOffset ? nil : k
                    }
                }))
                // Move or kill line-annotations.
                let lineAnnos = annotation.lineAnnotations.compactMap({ (i,x) -> (Int,CodeLineAnnotation)? in
                    if i <= rangeToReplace.lowerBound.lineOffset {
                        return (i,x)
                    }
                    else {
                        let k = i + -removeLineCount + newLineCharCount
                        return k <= rangeToReplace.lowerBound.lineOffset ? nil : (k,x)
                    }
                })
                annotation.lineAnnotations.removeAll()
                for (i,x) in lineAnnos {
                    annotation.lineAnnotations[i] = x
                }
            }
            switch mm {
            case let .mouse(mmm):
                switch mmm.kind {
                case .down:
                    let layout = CodeLayout(
                        config: editing.config,
                        storage: editing.storage,
                        imeState: editing.imeState,
                        boundingWidth: mmm.bounds.width)
                    if mmm.pointInBounds.x < editing.config.rendering.breakpointWidth {
                        let lineOffset = layout.clampingLineOffset(at: mmm.pointInBounds.y)
                        annotation.toggleBreakPoint(at: lineOffset)
                    }
                default: break
                }
            default: break
            }
        }
    }
}

