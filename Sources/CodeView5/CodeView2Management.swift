//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/20/19.
//

import Foundation

/// Pre-built code-text processing engine.
///
/// This is designed to provide minimum default code-text editing engine.
/// You can build more features around this.
///
/// Tracking Content Changes
/// ------------------------
/// To track contet (text) changes, see `CodeSource.timeline`.
/// It contains changes happen in `CodeSource.storage` since last emission.
/// The timeline will be emptied each time after note emission.
/// **If `CodeSource.timeline` is empty, it means whole snapshot replacement**.
/// This can happen by content reloading or undo/redo operation.
/// In that case, you must abandon any existing content
/// and should replace all from the source.
///
public struct CodeView2Management {
    public private(set) var state = State()
    public struct State {
        public var config = CodeConfig()
        public var state = CodeState()
        public var preventedTypingCommands = Set<TextTypingCommand>()
        public var invalidatedRegion = CodeEditingInvalidatedRegion.none
        /// Defines whow completion window to be rendered.
        /// `nil` means completion window should be disappeared.
        public var completionWindowState = CompletionWindowState?.none
        public struct CompletionWindowState {
            public var aroundRange = CodeStoragePosition.zero..<CodeStoragePosition.zero
            public init() {}
        }
    }

    public typealias Message = CodeUserInteractionScanningMessage
    public typealias Note = CodeEditingStateRenderingMessage
    public enum Effect {
        case replacePasteboardContent(String)
    }
    
    public init() {}
    public mutating func process(_ m:Message) -> [Effect] {
        guard shouldProcessMessage(m) else { return [] }
        switch m {
        case let .edit(mm): return processEdit(mm)
        case let .menu(mm): return processMenu(mm)
        case let .view(mm): return processView(mm)
        case let .setPreventedTypingCommands(pcmds):
            state.preventedTypingCommands = pcmds
            return []
        }
    }
    private func shouldProcessMessage(_ m:Message) -> Bool {
        switch m {
        case let .edit(edm):
            switch edm {
            case let .typing(n):
                switch n {
                case let .processEditingCommand(cmd):
                    return !state.preventedTypingCommands.contains(cmd)
                default:
                    return true
                }
            default:
                return true
            }
        case .menu(_):
            return true
        case .view(_):
            return true
        case .setPreventedTypingCommands(_):
            return true
        }
    }
    
    private mutating func processEdit(_ mm:CodeEditingMessage) -> [Effect] {
        var editing = CodeEditing(config: state.config, state: state.state)
        editing.apply(mm)
        state.state = editing.state
        state.state.source.cleanTimeline()
        /// Render after setting config/state
        /// so they can calculate based on latest state correctly.
        state.invalidatedRegion = editing.invalidatedRegion
        
        switch mm {
        case let .typing(mmm):
            switch mmm {
            case let .processEditingCommand(mmmm):
                switch mmmm {
                case .cancelOperation:
                    state.preventedTypingCommands = []
                    state.completionWindowState = nil
                case .moveUp:
                    print("MOVE UP")
                case .moveDown:
                    print("MOVE DOWN")
                default: break
                }
            default: break
            }
        default: break
        }
        return []
    }
    private mutating func processMenu(_ mm:Message.MenuMessage) -> [Effect] {
        switch mm {
        case .copy:
            let sss = state.state.source.lineContentsInCurrentSelection()
            let s = sss.joined(separator: "\n")
            return [.replacePasteboardContent(s)]
        case .cut:
            let sss = state.state.source.lineContentsInCurrentSelection()
            let s = sss.joined(separator: "\n")
            state.state.source.replaceCharactersInCurrentSelection(with: "")
            state.state.recordTimePoint(as: .alienEditing(nameForMenu: "Cut"))
            state.invalidatedRegion = .all
            return [.replacePasteboardContent(s)]
        case let .paste(s):
            state.state.source.replaceCharactersInCurrentSelection(with: s)
            state.state.recordTimePoint(as: .alienEditing(nameForMenu: "Paste"))
            state.invalidatedRegion = .all
            return []
        case .selectAll:
            state.state.source.selectAll()
            state.invalidatedRegion = .all
            return []
//        case let .replace(withContent, nameForMenu):
        case .undo:
            guard state.state.timeline.canUndo else { return [] }
            state.state.undoInTimeline()
            state.invalidatedRegion = .all
            return []
        case .redo:
            guard state.state.timeline.canRedo else { return [] }
            state.state.redoInTimeline()
            state.invalidatedRegion = .all
            return []
        }
    }
    private mutating func processView(_ mm:Message.ViewMessage) -> [Effect] {
        switch mm {
        case .becomeFirstResponder:
            state.completionWindowState = nil
            return []
        case .resignFirstResponder:
            state.completionWindowState = nil
            return []
        }
    }
}

