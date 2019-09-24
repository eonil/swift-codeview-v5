//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/20/19.
//

import Foundation

public extension CodeEditing {
    func makeLayout(in width: CGFloat) -> CodeLayout {
        return CodeLayout(
            config: config,
            storage: storage,
            imeState: imeState,
            boundingWidth: width)
    }
}
public extension CodeStorage {
    @available(*, deprecated: 0)
    func makeLayout(config: CodeConfig, imeState: IMEState?, boundingWidth: CGFloat) -> CodeLayout {
        return CodeLayout(
            config: config,
            storage: self,
            imeState: imeState,
            boundingWidth: boundingWidth)
    }
}
