//
//  CodeSourceConfig.swift
//  
//
//  Created by Henry Hathaway on 9/5/19.
//

import Foundation
import AppKit

/// Defines how editor work.
///
/// This provides common parameters for editor operations.
/// That means, this is not really a part of code editing state.
/// This is **parameters** to be spplied to each operations.
/// Therefore, modifying config won't be regarded as state update.
///
public struct CodeConfig {
    public var editing = Editing()
    public var rendering = Rendering()
    public struct Editing {
        public var tabSpaceCount = 4
        public func makeTabReplacement() -> String {
            return String(repeating: " ", count: tabSpaceCount)
        }
        /// Adds same amount of indent with above line.
        public var autoIndent = true
        /// Increase indentation level if above line contains this string.
        public var indentStart = "{"
        /// Decreases indentation level if above line contains this string.
        public var indentEnd = "}"
        
//        /// For consecutive non-whitespace string
//        public var wordSeparators = [" ", ".", ":"]
        public var preventSomeEditingCommandsOnCompletionVisible = true
    }
    public struct Rendering {
        // Treats font object as an immutable value.
        public var font = defaultFont
        public var textLineBackgroundColor = NSColor(hue: 0, saturation: 0, brightness: 0, alpha: 1)
        public var currentTextLineBackgroundColor = NSColor(hue: 0, saturation: 0, brightness: 0.1, alpha: 1)
        public var selectionColor = NSColor.selectedTextBackgroundColor
        public var textColor = NSColor(hue: 0, saturation: 0, brightness: 0.8, alpha: 1)
        public var selectedTextBackgroundColor = NSColor(hue: 0, saturation: 0, brightness: 0.3, alpha: 1)
        public var selectedTextCharacterColor = NSColor(hue: 0, saturation: 0, brightness: 1, alpha: 1)
        public var lineNumberFont = NSFont.monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
        public var lineNumberColor = NSColor.textColor.blended(withFraction: 0.5, of: NSColor.textBackgroundColor) ?? NSColor.textColor
        public var lineNumberColorOnBreakPoint = NSColor.textColor
        public var breakPointColor = NSColor.controlAccentColor
        public var annotationFont = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
        
        /// Always use font with same line height.
        /// Result undefined if you use fonts of different sizes.
        public var styling = [
            .plain: StyleDetail(
                font: defaultFont,
                color: grey(0.6)),
            .keyword: StyleDetail(
                font: defaultBoldFont,
                color: grey(0.8)),
            .moduleIdentifier: StyleDetail(
                font: defaultBoldFont,
                color: grey(0.8)),
            .typeIdentifier: StyleDetail(
                font: defaultFont,
                color: grey(0.8)),
            .memberIdentifier: StyleDetail(
                font: defaultFont,
                color: grey(0.8)),
            ] as [CodeStyle: StyleDetail]
        public struct StyleDetail {
            public var font = defaultFont
            public var color = grey(0.6)
        }
        
        var lineHeight: CGFloat { -font.descender + font.ascender }
        var breakpointWidth: CGFloat { lineHeight * 3 }
        var lineNumberAreaWidth: CGFloat { lineHeight * 2 }
        var gapBetweenBreakpointAndBody = CGFloat(5)
        var bodyX: CGFloat { breakpointWidth + gapBetweenBreakpointAndBody }
    }
    public init() {}
}

private func grey(_ brightness: CGFloat) -> NSColor {
    return NSColor(hue: 0, saturation: 0, brightness: brightness, alpha: 1)
}
private let defaultBoldFont = {
    return NSFont(name: "SF Mono Bold", size: NSFont.systemFontSize)
        ?? NSFont(name: "Menlo Bold", size: NSFont.systemFontSize)
        ?? NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .bold)
}() as NSFont
private let defaultFont = {
    return NSFont(name: "SF Mono", size: NSFont.systemFontSize)
        ?? NSFont(name: "Menlo", size: NSFont.systemFontSize)
        ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
}() as NSFont
