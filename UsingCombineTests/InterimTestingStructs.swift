//
//  InterimTestingStructs.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 7/20/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import Foundation

/*
 Generic interim tuples, specifically for testing equality from functions
 where tuples are return or used heavily instead of explicit structs.
 */
struct Tuple2<T0, T1> {
    let t0: T0
    let t1: T1

    init(_ tuple: (T0, T1)) {
        t0 = tuple.0
        t1 = tuple.1
    }

    var raw: (T0, T1) { (t0, t1) }
}

extension Tuple2: Equatable where T0: Equatable, T1: Equatable {}
extension Tuple2: Hashable where T0: Hashable, T1: Hashable {}

struct Tuple3<T0, T1, T2> {
    let t0: T0
    let t1: T1
    let t2: T2

    init(_ tuple: (T0, T1, T2)) {
        t0 = tuple.0
        t1 = tuple.1
        t2 = tuple.2
    }

    var raw: (T0, T1, T2) { (t0, t1, t2) }
}

extension Tuple3: Equatable where T0: Equatable, T1: Equatable, T2: Equatable {}
extension Tuple3: Hashable where T0: Hashable, T1: Hashable, T2: Hashable {}

struct Tuple4<T0, T1, T2, T3> {
    let t0: T0
    let t1: T1
    let t2: T2
    let t3: T3

    init(_ tuple: (T0, T1, T2, T3)) {
        t0 = tuple.0
        t1 = tuple.1
        t2 = tuple.2
        t3 = tuple.3
    }

    var raw: (T0, T1, T2, T3) { (t0, t1, t2, t3) }
}

extension Tuple4: Equatable where T0: Equatable, T1: Equatable, T2: Equatable, T3: Equatable {}
extension Tuple4: Hashable where T0: Hashable, T1: Hashable, T2: Hashable, T3: Hashable {}
