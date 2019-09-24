//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/21/19.
//

import BTree

public typealias BTSet<K> = SortedSet<K> where K:Comparable
public typealias BTMap<K,V> = Map<K,V> where K:Comparable
public typealias BTList<T> = List<T>
