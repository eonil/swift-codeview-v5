//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/20/19.
//

import Foundation

public extension CodeSource {
    func makeLayout(config: CodeConfig, imeState: IMEState, boundingWidth: CGFloat) -> CodeLayout {
        return CodeLayout(config: config, source: self, imeState: imeState, boundingWidth: boundingWidth)
    }
}
