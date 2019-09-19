//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/19/19.
//

import Foundation

/// REPL core of code processing.
///
/// This accepts text-typing notes and extra editing commands
/// to process text editing state -- characters and selections.
///
/// Awaiting Synchronization
/// ------------------------
///
///
final class CodeManagement {
    private let processingQueue: DispatchQueue
    private var config = CodeConfig()
    private var state = CodeState()
    private func process(_ c:CodeEditing.Control, with key: Key) {
        var editing = CodeEditing(config: config, state: state)
        editing.process(c)
        state = editing.state
        let stateToNote = state
        state.source.cleanTimeline()
        note?(Note(
            key: key,
            config: config,
            state: stateToNote,
            invalidatedRegion: editing.invalidatedRegion))
    }
    
    /// Supplied queue must be a serial queue.
    init(_ q:DispatchQueue = makeDefaultQueue()) {
        processingQueue = q
    }
    /// Performs control asynchronously.
    /// Calling control always produces a matching `Note`.
    /// They are 1:1 mapped.
    /// Produced note contains `key` used with calling `control`.
    /// You can use the `key` to identify which note came from which control.
    func control(_ c:CodeEditing.Control, with key: Key) {
        processingQueue.async { [weak self] in self?.process(c, with: key) }
    }
    
    var note: ((Note) -> Void)?
    struct Note {
        /// Key for control command that applied at last on this state.
        var key = 0 as Key
        /// Configuration applied at time of control.
        var config: CodeConfig
        var state: CodeState
        var invalidatedRegion: CodeEditing.InvalidatedRegion
    }
    typealias Key = Int
}

private func makeDefaultQueue() -> DispatchQueue {
    return DispatchQueue(
        label: "CodeManagement/Processing",
        qos: .userInitiated,
        autoreleaseFrequency: .workItem)
}
