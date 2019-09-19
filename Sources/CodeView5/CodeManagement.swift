//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/19/19.
//

import Foundation

private let metaManagementQueue = DispatchQueue(label: "CodeManagement/MetaManagement")
private var keySeed = 0
private var table = [CodeManagement.Key: () -> CodeManagement?]()
private func makeKey() -> Int {
    return metaManagementQueue.sync {
        keySeed += 1
        return keySeed
    }
}

public extension CodeManagement {
    /// Finds management object for the key.
    static func search(for k:CodeManagement.Key) -> CodeManagement? {
        return metaManagementQueue.sync {
            return table[k]?()
        }
    }
}

/// REPL core of code processing.
///
/// This accepts text-typing notes and extra editing commands
/// to process text editing state -- characters and selections.
///
/// You can consider this as a server for `CodeView` client.
///
/// Conflict, Priority & Synchronization
/// ------------------------------------
/// I didn't expect this situation. I realized that I need serious synchronization
/// after I converted this into asynchronous server/client structure.
///
/// The best known way to solve this is CRDT, but I don't want it now.
/// Just I don't want to put too much energy on bootstraping implementation.
/// Therefore, I choose the simplest solution.
///
/// - Run whole server soley in main thread.
/// - User-interaction client `CodeView` runs in main thread only.
/// - Therefore, synchronization issue won't happen.
/// - Messages from other client (e.g. RLS) will be transferred to main thread.
/// - Changes made by RLS will be sent to `CodeView` client synchronosuly.
/// - Therefore, no issue.
///
/// I know this is suboptimal, or inferior solution.
/// But this is the most time-saving solution IMO.
///
public final class CodeManagement {
    private var config = CodeConfig()
    private var state = CodeState()
    /// `CodeView` can send messages directly into `process` function.
    func process(_ c:Control) {
        switch c {
        case .query:
            note?(.snapshot(CodeManagement.Note.Snapshot(
                config: config,
                state: state,
                invalidatedRegion: .all)))
        case let .editing(edc):
            var editing = CodeEditing(config: config, state: state)
            editing.process(edc)
            state = editing.state
            let stateToNote = state
            state.source.cleanTimeline()
            note?(.snapshot(CodeManagement.Note.Snapshot(
                config: config,
                state: stateToNote,
                invalidatedRegion: editing.invalidatedRegion)))
        }
    }
    public let key = makeKey()
    public typealias Key = Int
    
    public init() {
        metaManagementQueue.sync {
            table[key] = { [weak self] in self }
        }
    }
    deinit {
        metaManagementQueue.sync {
            table[key] = nil
        }
    }
    
    /// Performs control asynchronously.
    func control(_ c:Control) {
        DispatchQueue.main.async { [weak self] in self?.process(c) }
    }
    enum Control {
        /// Requests current server state.
        case query
        case editing(CodeEditing.Control)
    }
    
    public var note: ((Note) -> Void)?
    public enum Note {
        /// Key for control command that applied at last on this state.
        case snapshot(Snapshot)
        public struct Snapshot {
            /// Configuration applied at time of control.
            public var config: CodeConfig
            var state: CodeState
            var invalidatedRegion: CodeEditing.InvalidatedRegion
            public var source: CodeSource { state.source }
        }
    }
}
