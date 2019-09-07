////
////  File.swift
////  
////
////  Created by Henry Hathaway on 9/7/19.
////
//
//import Foundation
////
////
///////// Trial to fix insane design of `UndoManager`.
///////// `UndoManager` is standard for insanity of imperative programming.
///////// It is state-ful, cryptic, opaque and order-dependent.
///////// This provides an adapter to make your life easier for your own
///////// functional-style undo/redo implementation.
//////final class UndoRedoAdapter {
//////    var timeline = CodeTimeline()
//////    weak var manager: UndoManager?
//////    
//////    func recordSnapshotPoint(undo: @escaping() -> Void, redo: @escaping () -> Void) {
//////        manager?.registerUndo(withTarget: self, handler: { _ in
//////            // Undo.
//////            undo()
//////            // Record redo here.
//////            manager?.registerUndo(withTarget: self, handler: { _ in
//////                redo()
//////            })
//////        })
//////    }
//////    private func performUndo() {
//////        // Record redo here.
//////        manager?.registerUndo(withTarget: self, handler: { _ in
//////            // Redo.
//////        })
//////    }
//////}
////
////extension UndoManager {
////    func recordSnapshotPoint(name: String, undo: @escaping() -> Void, redo: @escaping () -> Void) {
////        registerUndo(withTarget: self, handler: { ss in
////            ss.disableUndoRegistration()
////            // Record redo here.
////            ss.registerUndo(withTarget: self, handler: { _ in
////                redo()
////            })
////            ss.enableUndoRegistration()
////            undo()
////        })
////        setActionName(name)
////    }
////}
