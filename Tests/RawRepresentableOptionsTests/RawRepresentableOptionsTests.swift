//
//  RawRepresentableOptionsTests.swift
//  RawRepresentableOptions
//
//  Created by Scott James Remnant on 10/7/26.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling.
// Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(RawRepresentableOptionsMacros)
import RawRepresentableOptionsMacros

@MainActor let testMacros: [String: Macro.Type] = [
    "RawRepresentableOptions": RawRepresentableOptionsMacro.self,
]
#endif

@MainActor
struct RawRepresentableOptionsTests {
    @Test
    func `@RawRepresentableOptions wraps Options enum`() throws {
        #if canImport(RawRepresentableOptionsMacros)
        assertMacroExpansion(
            """
            @RawRepresentableOptions
            struct Test {
                private enum Options: String {
                    case frodo
                    case bilbo
                }
            }
            """,
            expandedSource: """
            struct Test {
                private enum Options: String {
                    case frodo
                    case bilbo
                }

                static let frodo: Self = Self(rawValue: Options.frodo.rawValue)

                static let bilbo: Self = Self(rawValue: Options.bilbo.rawValue)

                typealias RawValue = String

                var rawValue: RawValue

                init(rawValue: RawValue) {
                    self.rawValue = rawValue
                }
            }

            extension Test: RawRepresentable {
            }
            """,
            macros: testMacros,
        )
        #else
        try Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test
    func `@RawRepresentableOptions can only be applied to a struct`() throws {
        #if canImport(RawRepresentableOptionsMacros)
        assertMacroExpansion(
            """
            @RawRepresentableOptions
            enum Test {
                private enum Options: String {
                    case frodo
                    case bilbo
                }
            }
            """,
            expandedSource: """
            enum Test {
                private enum Options: String {
                    case frodo
                    case bilbo
                }
            }

            extension Test: RawRepresentable {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@RawRepresentableOptions can only be applied to a struct",
                    line: 1,
                    column: 1,
                ),
            ],
            macros: testMacros,
        )
        #else
        try Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test
    func `@RawRepresentableOptions provides CaseIterable conformance`() throws {
        #if canImport(RawRepresentableOptionsMacros)
        assertMacroExpansion(
            """
            @RawRepresentableOptions
            struct Test: CaseIterable {
                private enum Options: String {
                    case frodo
                    case bilbo
                }
            }
            """,
            expandedSource: """
            struct Test: CaseIterable {
                private enum Options: String {
                    case frodo
                    case bilbo
                }

                static let frodo: Self = Self(rawValue: Options.frodo.rawValue)

                static let bilbo: Self = Self(rawValue: Options.bilbo.rawValue)

                static let allCases: [Self] = [.frodo, .bilbo]

                typealias RawValue = String

                var rawValue: RawValue

                init(rawValue: RawValue) {
                    self.rawValue = rawValue
                }
            }

            extension Test: RawRepresentable {
            }
            """,
            macros: testMacros,
        )
        #else
        try Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test
    func `@RawRepresentableOptions synthesizes members have parent access`() throws {
        #if canImport(RawRepresentableOptionsMacros)
        assertMacroExpansion(
            """
            @RawRepresentableOptions
            public struct Test: CaseIterable {
                private enum Options: String {
                    case frodo
                    case bilbo
                }
            }
            """,
            expandedSource: """
            public struct Test: CaseIterable {
                private enum Options: String {
                    case frodo
                    case bilbo
                }

                public static let frodo: Self = Self(rawValue: Options.frodo.rawValue)

                public static let bilbo: Self = Self(rawValue: Options.bilbo.rawValue)

                public static let allCases: [Self] = [.frodo, .bilbo]

                public typealias RawValue = String

                public var rawValue: RawValue

                public init(rawValue: RawValue) {
                    self.rawValue = rawValue
                }
            }

            extension Test: RawRepresentable {
            }
            """,
            macros: testMacros,
        )
        #else
        try Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test
    func `@RawRepresentableOptions works when enum cases have associated values`() throws {
        #if canImport(RawRepresentableOptionsMacros)
        assertMacroExpansion(
            """
            @RawRepresentableOptions
            struct Test: CaseIterable {
                private enum Options: String {
                    case frodo = 33
                    case bilbo = 111
                }
            }
            """,
            expandedSource: """
            struct Test: CaseIterable {
                private enum Options: String {
                    case frodo = 33
                    case bilbo = 111
                }

                static let frodo: Self = Self(rawValue: Options.frodo.rawValue)

                static let bilbo: Self = Self(rawValue: Options.bilbo.rawValue)

                static let allCases: [Self] = [.frodo, .bilbo]

                typealias RawValue = String

                var rawValue: RawValue

                init(rawValue: RawValue) {
                    self.rawValue = rawValue
                }
            }

            extension Test: RawRepresentable {
            }
            """,
            macros: testMacros,
        )
        #else
        try Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test
    func `@RawRepresentableOptions works when enum cases are backticked`() throws {
        #if canImport(RawRepresentableOptionsMacros)
        assertMacroExpansion(
            """
            @RawRepresentableOptions
            struct Test: CaseIterable {
                private enum Options: String {
                    case `frodo`
                    case `bilbo`
                }
            }
            """,
            expandedSource: """
            struct Test: CaseIterable {
                private enum Options: String {
                    case `frodo`
                    case `bilbo`
                }

                static let `frodo`: Self = Self(rawValue: Options.`frodo`.rawValue)

                static let `bilbo`: Self = Self(rawValue: Options.`bilbo`.rawValue)

                static let allCases: [Self] = [.`frodo`, .`bilbo`]

                typealias RawValue = String

                var rawValue: RawValue

                init(rawValue: RawValue) {
                    self.rawValue = rawValue
                }
            }

            extension Test: RawRepresentable {
            }
            """,
            macros: testMacros,
        )
        #else
        try Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }
}
