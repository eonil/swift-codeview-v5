//
//  CodeSourceConfig.swift
//  
//
//  Created by Henry Hathaway on 9/5/19.
//

import Foundation
import AppKit

public struct CodeSourceConfig {
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
    }
    public struct Rendering {
        // Treats font object as a value.
        public var font = NSFont(name: "SF Mono", size: NSFont.systemFontSize) ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
        public var selectionColor = NSColor.selectedTextBackgroundColor
        public var textColor = NSColor.textColor
        public var selectedTextBackgroundColor = NSColor.selectedTextBackgroundColor
        public var lineNumberFont = NSFont(name: "SF Compact", size: NSFont.smallSystemFontSize) ?? NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        public var lineNumberColor = NSColor.textColor.blended(withFraction: 0.5, of: NSColor.textBackgroundColor) ?? NSColor.textColor
        public var breakPointColor = NSColor.controlAccentColor
        
        var lineHeight: CGFloat { -font.descender + font.ascender }
        var breakpointWidth: CGFloat { lineHeight * 3 }
        var gapBetweenBreakpointAndBody = CGFloat(5)
        var bodyX: CGFloat { breakpointWidth + gapBetweenBreakpointAndBody }
    }
}
 
