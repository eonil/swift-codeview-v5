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
    var bounds: CGRect {
        return CTLineGetBoundsWithOptions(self, [])
    }
}
