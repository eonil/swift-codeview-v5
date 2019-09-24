////
////  File.swift
////
////
////  Created by Henry Hathaway on 9/24/19.
////
//
//import Foundation
//
///// Compresses repeating elements.
//struct CompressingSmallList<T:Equatable>: RandomAccessCollection, MutableCollection, RangeReplaceableCollection {
//    var spans = [Span]()
//}
//
//private enum Content {
//    case empty
//    case repeatitionOfSingle(element:T, count:Int)
//    case multipleSpans([Span])
//}
//private struct Span<T> {
//    var element:T
//    var count:Int
//}
