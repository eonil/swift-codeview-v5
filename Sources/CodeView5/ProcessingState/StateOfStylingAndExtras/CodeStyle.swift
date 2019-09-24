//
//  CodeStyle.swift
//  
//
//  Created by Henry Hathaway on 9/5/19.
//

import Foundation

///
/// - TODO:
///     This can be represented in 4-bits.
///     Can be compressed naturally.
///     Would Swift compiler do that?
public enum CodeStyle {
    /// Default style for new, undetermined characters.
    case plain
    case keyword
    case numericLiteral
    case stringLiteral
    case moduleIdentifier
    case typeIdentifier
    case memberIdentifier
}

public extension CodeStyle {
    func repeatingSlice(count n:Int) -> ArraySlice<CodeStyle> {
        return codeStyleSlice(for: self, count: n)
    }
    static let all = [
        .plain,
        .keyword,
        .numericLiteral,
        .stringLiteral,
        .moduleIdentifier,
        .typeIdentifier,
        .memberIdentifier,
    ] as [CodeStyle]
}

/// Just a little bit of easy optimization.
private let prebuffers = Dictionary<CodeStyle,[CodeStyle]>(uniqueKeysWithValues: CodeStyle.all.map({ s in
    let a = Array<CodeStyle>(repeating: s, count: 1024)
    return (s,a)
}))
private func codeStyleSlice(for s:CodeStyle, count n:Int) -> ArraySlice<CodeStyle> {
    if n < prebuffers[s]!.count { return prebuffers[s]![0..<n] }
    return Array(repeating: .plain, count: n)[0..<n]
}


