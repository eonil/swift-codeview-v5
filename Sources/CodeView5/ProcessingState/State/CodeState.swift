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
struct CodeState {
    var timeline = CodeTimeline()
    var source = CodeSource()
    var imeState = IMEState?.none
    
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
