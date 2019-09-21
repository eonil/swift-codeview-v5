//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/21/19.
//

import BTree

typealias BTSet<K> = SortedSet<K> where K:Comparable
typealias BTMap<K,V> = Map<K,V> where K:Comparable
typealias BTList<T> = List<T>
