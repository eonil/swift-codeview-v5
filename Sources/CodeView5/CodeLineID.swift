//
//  CodeLineID.swift
//  CodeView5Demo
//
//  Created by Henry Hathaway on 9/4/19.
//  Copyright © 2019 Eonil. All rights reserved.
//

import Foundation

struct CodeLineID: Equatable, Hashable {
    private let ref = Ref()
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(ref))
    }
    static func == (_ a: CodeLineID, _ b: CodeLineID) -> Bool {
        return a.ref === b.ref
    }
}
private final class Ref {}
