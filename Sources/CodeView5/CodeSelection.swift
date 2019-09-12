//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/11/19.
//

import Foundation

protocol SubstringCollection: RandomAccessCollection where Element == Substring {}
extension CollectionOfOne: SubstringCollection where Element == Substring {}
extension Array: SubstringCollection where Element == Substring {}
