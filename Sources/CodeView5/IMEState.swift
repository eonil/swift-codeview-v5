//
//  IMEState.swift
//  
//
//  Created by Henry Hathaway on 9/5/19.
//

import Foundation

struct IMEState {
    var incompleteText = ""
    var selectionInIncompleteText = Range<String.Index>(uncheckedBounds: (.zero, .zero))
}
