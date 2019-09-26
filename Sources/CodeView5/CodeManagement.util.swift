//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/21/19.
//

import Foundation

public extension CodeManagement {
    func send(to codeView:CodeView) {
        codeView.control(.renderEditing(editing))
        codeView.control(.renderAnnotation(annotation))
    }
}
