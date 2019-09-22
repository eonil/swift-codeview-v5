//
//  CodeTimeline.swift
//  
//
//  Created by Henry Hathaway on 9/6/19.
//

import Foundation
import BTree

/// Manages undo/redo support.
public struct CodeTimeline {
    public private(set) var undoablePoints = List<Point>()
    public private(set) var currentPoint = Point()
    public private(set) var redoablePoints = List<Point>()
    public struct Point {
        /// Unique identifier to distinguish different snapshot points.
        public var version = 0 as Key
        var kind = CodeOperationKind.reloadAll
        public var snapshot = CodeStorage()
    }
    public typealias Key = Int
    private var keySeed = 0 as Key
    
    init() {}
    init(current s:CodeStorage) {
        currentPoint = Point(version: 1, kind: .reloadAll, snapshot: s)
    }
    public var canUndo: Bool { !undoablePoints.isEmpty }
    public var canRedo: Bool { !redoablePoints.isEmpty }
    mutating func record(_ s:CodeStorage, as kind: CodeOperationKind) {
        precondition(s.timeline.points.isEmpty)
        undoablePoints.append(currentPoint)
        keySeed += 1
        currentPoint = Point(version: keySeed, kind: kind, snapshot: s)
        redoablePoints.removeAll()
    }
    mutating func undo() {
        redoablePoints.insert(currentPoint, at: 0)
        currentPoint = undoablePoints.removeLast()
    }
    mutating func redo() {
        undoablePoints.append(currentPoint)
        currentPoint = redoablePoints.remove(at: 0)
    }
}

enum CodeOperationKind {
    /// Indicates whole source has been replaced by reloading by external I/O.
    /// Though you can undo/redo this kind of point programmatically,
    /// This won't be available to end-users because such reloading points
    /// won't be registered to `UndoManager`.
    case reloadAll
    case typingCharacter
    case typingNewLine
    /// Any operation done by external command.
    /// That includes control command and
    /// AppKit messages.
    case alienEditing(nameForMenu: String)
    case editingInteraction
    var isSignificant: Bool {
        switch self {
        case .reloadAll:            return true
        case .typingCharacter:      return false
        case .typingNewLine:        return true
        case .alienEditing(_):      return true
        case .editingInteraction:   return false
        }
    }
    var nameForMenu: String {
        switch self {
        case .reloadAll:            return ""
        case .typingCharacter:      return "Typing"
        case .typingNewLine:        return "Typing"
        case let .alienEditing(n):  return n
        case .editingInteraction:   return "Editing"
        }
    }
}
