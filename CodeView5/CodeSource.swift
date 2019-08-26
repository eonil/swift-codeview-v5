//
//  CodeSource.swift
//  CodeView5
//
//  Created by Henry on 2019/07/31.
//  Copyright © 2019 Eonil. All rights reserved.
//

import Foundation

struct CodeSource {
    var characters = [CodeLine]()
    var styles = [CodeLine]()
}
struct CodeLine {
    var spans = [CodeSpan]()
}
struct CodeSpan {
    var code = ""
    var style = CodeStyle.plain
}
enum CodeStyle {
    case plain
    case keyword
    case literal
    case identifier
}
