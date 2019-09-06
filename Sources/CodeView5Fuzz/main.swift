//
//  main.swift
//  
//
//  Created by Henry Hathaway on 9/6/19.
//

import Foundation
import CodeView5
import TestUtil

extension Double {
    var x: String {
        return String(format: "%.2f", self)
    }
}

let s = Date()
let n = 1_000_000
var m = CodeView5Mock()
var totalOpTime = 0 as TimeInterval
for i in 0..<n {
    totalOpTime += m.step()
    m.validate()
    if i % 1_000 == 0 {
        let c = m.target.lines.count
        let opsRatio = Double(i) / Double(totalOpTime)
        let totalRunTime = Date().timeIntervalSince(s)
        let opsRunTimeRatio = totalOpTime / totalRunTime
        print("\(i)/\(n): \(c) items, \(opsRatio.x) ops/sec, op/run: \(opsRunTimeRatio.x) = \(totalOpTime.x)s/\(totalRunTime.x)s")
    }
}
