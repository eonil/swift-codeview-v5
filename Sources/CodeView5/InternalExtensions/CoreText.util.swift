//
//  CoreText.util.swift
//  
//
//  Created by Henry Hathaway on 9/5/19.
//

import Foundation
import AppKit

extension CTLine {
    static func make(with ss:Substring, font f: NSFont, color c:NSColor = NSColor.textColor) -> CTLine {
        let s = String(ss)
        let x = NSAttributedString(string: s, attributes: [
            .font: f,
            .foregroundColor: c.cgColor,
        ])
        return CTLineCreateWithAttributedString(x)
    }
    @available(*, deprecated: 0)
    var __bounds: CGRect {
        return CTLineGetBoundsWithOptions(self, [])
    }
    var bounds: CGRect {
        return CTLineGetBoundsWithOptions(self, [.includeLanguageExtents])
    }
    var typographicBounds: (width:CGFloat, ascent:CGFloat, descent:CGFloat, leading:CGFloat) {
        var ascent = 0 as CGFloat
        var descent = 0 as CGFloat
        var leading = 0 as CGFloat
        let width = CTLineGetTypographicBounds(self, &ascent, &descent, &leading)
        return (CGFloat(width), ascent, descent, leading)
    }
}
