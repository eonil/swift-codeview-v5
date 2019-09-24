////
////  File.swift
////  
////
////  Created by Henry Hathaway on 9/24/19.
////
//
//import Foundation
//import AppKit
//
//public struct CodeAnnotationLayout {
//    let editingLayout: CodeLayout
//    let annotation: CodeAnnotation
//}
//public extension CodeAnnotationLayout {
//    /// Returns `nil` if there's no annotation at line offset.
//    func frameOfAllDiagnostics(at lineOffset: Int) -> CGRect? {
//        guard let anno = annotation.lineAnnotations[lineOffset] else { return nil }
//        let lineFrame = editingLayout.frameOfLine(at: lineOffset)
//        let diagSizes =
//        anno.diagnostics.map({ diag in
//            let msg = diag.message
//            let bounds
//            
//        })
//        let line = editingLayout.storage.text.lines.atOffset(lineOffset)
//        
//        
//    }
//    
//}
