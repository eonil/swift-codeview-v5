////
////  File.swift
////  
////
////  Created by Henry Hathaway on 9/23/19.
////
//
//import Foundation
//
//struct SparseList2<T>: RandomAccessCollection, MutableCollection, RangeReplaceableCollection {
//    private var impl = BTMap<Int,T>()
//    private(set) var count = 0
//    var startIndex: Int { impl.startIndex }
//    var endIndex: Int { impl.endIndex }
//    mutating func replaceSubrange<C, R>(_ subrange: R, with newElements: C) where C : Collection, R : RangeExpression, Element == C.Element, Index == R.Bound {
//        let q = subrange.relative(to: self)
//            
//    }
//}
