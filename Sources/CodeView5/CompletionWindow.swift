//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/20/19.
//

import Foundation
import AppKit

final class CompletionWindow: NSWindow {
    deinit {
        print("CompletionWindow deinit.")
    }
    override var canBecomeMain: Bool { false }
    override var canBecomeKey: Bool { false }
}
