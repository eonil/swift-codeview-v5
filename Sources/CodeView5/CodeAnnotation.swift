//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/23/19.
//

import Foundation

/// Extra data attached to each lines or characters.
/// Users can or cannot interact with annotations.
public struct CodeAnnotation {
    /// - Note:
    ///     You have to use only valid line offsets.
    /// - TODO: Optimize this.
    /// Need to be optimized.
    /// This would be okay for a while as most people do not install
    /// too many break-points. But if there are more than 100 break-points,
    /// this is very likely to make problems.
    public var breakPoints = Set<LineOffset>()
    /// Line offsets to annotation lines.
    /// This is sorted by kets -- line offsets.
    public var lineAnnotations = BTMap<LineOffset, CodeLineAnnotation>()
    public typealias LineOffset = Int
    public init() {}
}
public extension CodeAnnotation {
    mutating func toggleBreakPoint(at lineOffset: Int) {
        if breakPoints.contains(lineOffset) {
            breakPoints.remove(lineOffset)
        }
        else {
            breakPoints.insert(lineOffset)
        }
    }
}
public struct CodeLineAnnotation {
    /// Must be sorted by severity level.
    /// From weak to strong.
    public var diagnostics: [Diagnostic]
    public init(diagnostics ds: [Diagnostic] = []) {
        diagnostics = ds
    }
    public struct Diagnostic {
        public var message: String
        public var severity: Severity
        public init(message m: String, severity s: Severity) {
            message = m
            severity = s
        }
        public enum Severity {
            case info
            case warn
            case error
        }
    }
}
