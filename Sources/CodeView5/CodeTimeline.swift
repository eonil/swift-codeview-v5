//
//  CodeTimeline.swift
//  
//
//  Created by Henry Hathaway on 9/6/19.
//

import Foundation
import BTree

/// Manages undo/redo support.
struct CodeTimeline {
    private(set) var undoablePoints = List<Point>()
    private(set) var currentPoint = Point()
    private(set) var redoablePoints = List<Point>()
    struct Point {
        var kind = CodeOperationKind.reloadAll
        /// If end-user wants to undo/redo quickly, you might want to
        /// undo/redo multiple steps at once. In that case, you need
        /// to group steps by some basis, and consecutive (near)
        /// editing time-point can be a great option for it.
        var time = Date()
        var snapshot = CodeSource()
    }
    init() {}
    init(current s:CodeSource) {
        currentPoint = Point(kind: .reloadAll, time: Date(), snapshot: s)
    }
    var canUndo: Bool { !undoablePoints.isEmpty }
    var canRedo: Bool { !redoablePoints.isEmpty }
    mutating func record(_ s:CodeSource, as kind: CodeOperationKind) {
        undoablePoints.append(currentPoint)
        currentPoint = Point(kind: kind, time: Date(), snapshot: s)
        redoablePoints.removeAll()
    }
    mutating func undo() {
        redoablePoints.insert(currentPoint, at: 0)
        currentPoint = undoablePoints.removeLast()
    }
    mutating func undoContinuousEditings() {
        undo()
        while !undoablePoints.isEmpty {
            let dt = currentPoint.time.timeIntervalSince(undoablePoints.last!.time)
            guard dt < 1 else { break }
            undo()
        }
    }
    mutating func redo() {
        undoablePoints.append(currentPoint)
        currentPoint = redoablePoints.remove(at: 0)
    }
    mutating func redoContinuousEditings() {
        redo()
        while !redoablePoints.isEmpty {
            let dt = redoablePoints.first!.time.timeIntervalSince(currentPoint.time)
            guard dt < 1 else { break }
            redo()
        }
    }
}

enum CodeOperationKind {
    /// Indicates whole source has been replaced by reloading by external I/O.
    /// Though you can undo/redo this kind of point programmatically,
    /// This won't be available to end-user as such reloading points
    /// won't be registered to `UndoManager`.
    case reloadAll
    case typingCharacter
    case typingNewLine
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
