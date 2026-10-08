//
//  main.swift
//  RawRepresentableOptions
//
//  Created by Scott James Remnant on 10/7/26.
//

// swiftformat:disable redundantBackticks

import RawRepresentableOptions

@RawRepresentableOptions
public struct Test: Sendable, CaseIterable {
    private enum Options: String {
        case frodo
        case bilbo
        case `pippin`
        case meriadoc = "merry"
    }
}

var frodo = Test.frodo
var bilbo = Test.bilbo
var `pippin` = Test.`pippin`
var merry = Test.meriadoc

for fellow in [frodo, bilbo, `pippin`, merry] {
    print("\(String(reflecting: fellow.rawValue)) = \(String(reflecting: fellow))")
}

frodo = Test(rawValue: "frodo")
bilbo = Test(rawValue: "bilbo")
`pippin` = Test(rawValue: "pippin")
merry = Test(rawValue: "merry")
let gandalf = Test(rawValue: "gandalf")

for fellow in [frodo, bilbo, `pippin`, merry, gandalf] {
    print("\(String(reflecting: fellow.rawValue)) = \(String(reflecting: fellow))")
}
