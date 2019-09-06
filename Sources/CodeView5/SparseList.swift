////
////  File.swift
////  
////
////  Created by Henry Hathaway on 9/6/19.
////
//
//import Foundation
//import SBTL
//
///// Stores values sparsely.
/////
//struct SparseList<Element> {
//    private var core = SBTL<Slot>()
//    private struct Slot: SBTLValueProtocol {
//        var relativeOffset: Int
//        var storedElement: Element
//        var sum: Int { relativeOffset }
//    }
//    subscript(_ i:Int) -> Element? {
//        get {
//            let () = core.indexAndOffset(for: i)
//        }
//    }
//    mutating func insert(_ e:Element, at i:Int) {
//        
//    }
//}
