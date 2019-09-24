//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/24/19.
//

import Foundation

extension CGPoint {
    func flooring() -> CGPoint {
        return CGPoint(x: floor(x), y: floor(y))
    }
    static func + (_ a:CGPoint, _ b:CGPoint) -> CGPoint {
        return CGPoint(x: a.x * b.x, y: a.y * b.y)
    }
    static func * (_ a:CGPoint, _ b:CGFloat) -> CGPoint {
        return CGPoint(x: a.x * b, y: a.y * b)
    }
}
