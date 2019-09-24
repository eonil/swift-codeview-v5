//
//  File.swift
//
//
//  Created by Henry Hathaway on 9/24/19.
//

import Foundation

extension CGSize {
    func ceiling() -> CGSize {
        return CGSize(width: ceil(width), height: ceil(height))
    }
    static func * (_ a:CGSize, _ b:CGFloat) -> CGSize {
        return CGSize(width: a.width * b, height: a.height * b)
    }
}
