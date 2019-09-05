//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/5/19.
//

import Foundation

public struct CodeSourceEditingConfig {
    /// Replaces inserted tab with this string.
    public var tabReplacement = "    "
    /// Adds same amount of indent with above line.
    public var autoIndent = true
    /// Increase indentation level if above line contains this string.
    public var indentStart = "{"
    /// Decreases indentation level if above line contains this string.
    public var indentEnd = "}"
}
