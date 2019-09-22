//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/6/19.
//

import Foundation
import CodeView5
import TestUtil

struct CodeView5Mock {
    private(set) var prng = ReproduciblePRNG(1_000_000)
    private(set) var mode = Mode.increase
    private(set) var target = CodeTextStorage()
    /// - Returns: Time taken in single operation.
    mutating func step() -> TimeInterval {
        let c = prng.nextWithRotation(in: 0..<mode.ops.count)
        let op = target.lines.count == 0 ? .insertRandom : mode.ops[c]
        let t: TimeInterval
        switch op {
        case .insertRandom:
            let p = prng.nextWithRotation(in: 0..<target.lines.count+1)
            t = measureTimeUsingMach {
                target.lines.insert(CodeLine(), at: p)
            }
        case .replaceRandom:
            let p = prng.nextWithRotation(in: 0..<target.lines.count)
            t = measureTimeUsingMach {
                target.lines[p] = CodeLine()
            }
        case .removeRandom:
            let p = prng.nextWithRotation(in: 0..<target.lines.count)
            t = measureTimeUsingMach {
                target.lines.remove(at: p)
            }
        }
        
        switch mode {
        case .increase:
            if target.lines.count > 10_000 { mode = .decrease }
        case .decrease:
            if target.lines.count < 10 { mode = .increase }
        }
        return t
    }
    func validate() {
//        let ks = Set(target.keys)
//        precondition(ks.count == target.keys.count)
    }
}
extension CodeView5Mock {
    enum Operation {
        case insertRandom
        case replaceRandom
        case removeRandom
    }
    enum Mode {
        case increase
        case decrease
        var ops: [Operation] {
            switch self {
            case .increase:
                return [
                    .insertRandom,
                    .insertRandom,
                    .insertRandom,
                    .replaceRandom,
                    .removeRandom,
                ]
            case .decrease:
                return [
                    .insertRandom,
                    .replaceRandom,
                    .removeRandom,
                    .removeRandom,
                    .removeRandom,
                ]
            }
        }
    }

}
