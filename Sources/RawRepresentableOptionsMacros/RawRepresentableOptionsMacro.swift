//
//  RawRepresentableOptionsMacro.swift
//  RawRepresentableOptionsMacros
//
//  Created by Scott James Remnant on 10/7/26.
//

import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum RawRepresentableOptionsMacro {}

extension RawRepresentableOptionsMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext,
    ) throws -> [DeclSyntax] {
        // Make sure that @RawRepresentableOptions is applied to a struct.
        guard declaration.is(StructDeclSyntax.self) else {
            context.diagnose(Diagnostic(node: node, message: RawRepresentableOptionsDiagnostic.onlyApplicableToStruct))
            return []
        }

        // Find the first enum member.
        guard let enumDecl = declaration.memberBlock
            .members
            .compactMap({ $0.decl.as(EnumDeclSyntax.self) })
            .first
        else {
            context.diagnose(Diagnostic(node: node, message: RawRepresentableOptionsDiagnostic.requiresMemberEnum))
            return []
        }

        // Extract RawValue type.
        guard let rawValueType = enumDecl.inheritanceClause?.inheritedTypes.first?.type else {
            context.diagnose(Diagnostic(
                node: node,
                message: RawRepresentableOptionsDiagnostic.requiresEnumRawValueType,
            ))
            return []
        }

        // Extract greater-than-internal access modifier.
        let access = declaration.modifiers
            .first {
                switch $0.name.tokenKind {
                case .keyword(.open): true
                case .keyword(.public): true
                case .keyword(.package): true
                default: false
                }
            }

        let accessModifiers = [access].compactMap(\.self)

        // Extract all the enum elements.
        let enumCaseDecls = enumDecl.memberBlock
            .members
            .compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
            .flatMap(\.elements)

        // Synthesize a static variable declaration for each enum element.
        var decls: [DeclSyntax] = enumCaseDecls
            .map { enumCaseDecl in
                VariableDeclSyntax(
                    modifiers: DeclModifierListSyntax(accessModifiers + [DeclModifierSyntax(name: .keyword(.static))]),
                    bindingSpecifier: .keyword(.let),
                ) {
                    PatternBindingListSyntax {
                        PatternBindingSyntax(
                            pattern: IdentifierPatternSyntax(identifier: enumCaseDecl.name.trimmed),
                            typeAnnotation: TypeAnnotationSyntax(type: IdentifierTypeSyntax(name: .identifier("Self"))),
                            initializer: InitializerClauseSyntax(
                                value: FunctionCallExprSyntax(
                                    calledExpression: DeclReferenceExprSyntax(baseName: .keyword(.Self)),
                                    leftParen: .leftParenToken(),
                                    rightParen: .rightParenToken(),
                                ) {
                                    LabeledExprListSyntax {
                                        LabeledExprSyntax(
                                            label: "rawValue",
                                            expression: ExprSyntax(
                                                "\(enumDecl.name.trimmed).\(enumCaseDecl.name.trimmed).rawValue",
                                            ),
                                        )
                                    }
                                },
                            ),
                        )
                    }
                }
            }
            .map(DeclSyntax.init)

        // Synthesize allCases if requested and not already provided.
        let isCaseIterable = declaration.inheritanceClause?
            .inheritedTypes
            .contains { $0.type.trimmedDescription == "CaseIterable" } ?? false
        let hasAllCases = declaration.memberBlock
            .members
            .contains { memberBlockItem in
                if let variableDecl = memberBlockItem.decl.as(VariableDeclSyntax.self),
                   variableDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }),
                   variableDecl.bindings.contains(where: {
                       $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.trimmedDescription == "allCases"
                   })
                {
                    true
                } else {
                    false
                }
            }

        if isCaseIterable, !hasAllCases {
            let allCasesPropertyDecl = VariableDeclSyntax(
                modifiers: DeclModifierListSyntax(accessModifiers + [DeclModifierSyntax(name: .keyword(.static))]),
                bindingSpecifier: .keyword(.let),
            ) {
                PatternBindingListSyntax {
                    PatternBindingSyntax(
                        pattern: IdentifierPatternSyntax(identifier: .identifier("allCases")),
                        typeAnnotation: TypeAnnotationSyntax(
                            type: ArrayTypeSyntax(element: IdentifierTypeSyntax(name: .identifier("Self"))),
                        ),
                        initializer: InitializerClauseSyntax(value: ArrayExprSyntax(expressions: enumCaseDecls
                                .map { enumCaseDecl in
                                    ExprSyntax(".\(enumCaseDecl.name.trimmed)")
                                })),
                    )
                }
            }
            decls.append(DeclSyntax(allCasesPropertyDecl))
        }

        // RawValue typealias.
        let rawValueTypeAliasDecl = TypeAliasDeclSyntax(
            modifiers: DeclModifierListSyntax(accessModifiers),
            name: .identifier("RawValue"),
            initializer: TypeInitializerClauseSyntax(value: rawValueType),
        )
        decls.append(DeclSyntax(rawValueTypeAliasDecl))

        // rawValue property.
        let rawValuePropertyDecl = VariableDeclSyntax(
            modifiers: DeclModifierListSyntax(accessModifiers),
            bindingSpecifier: .keyword(.var),
        ) {
            PatternBindingListSyntax {
                PatternBindingSyntax(
                    pattern: IdentifierPatternSyntax(identifier: .identifier("rawValue")),
                    typeAnnotation: TypeAnnotationSyntax(type: IdentifierTypeSyntax(name: .identifier("RawValue"))),
                )
            }
        }
        decls.append(DeclSyntax(rawValuePropertyDecl))

        // RawRepresentable initalizer.
        let rawRepresentableInitDecl = InitializerDeclSyntax(
            modifiers: DeclModifierListSyntax(accessModifiers),
            signature: FunctionSignatureSyntax(parameterClause: FunctionParameterClauseSyntax(
                parameters: FunctionParameterListSyntax {
                    FunctionParameterSyntax(
                        firstName: .identifier("rawValue"),
                        type: IdentifierTypeSyntax(name: .identifier("RawValue")),
                    )
                },
            )),
        ) {
            "self.rawValue = rawValue"
        }
        decls.append(DeclSyntax(rawRepresentableInitDecl))

        return decls
    }
}

extension RawRepresentableOptionsMacro: ExtensionMacro {
    public static func expansion(
        of _: AttributeSyntax,
        attachedTo _: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo _: [TypeSyntax],
        in _: some MacroExpansionContext,
    ) throws -> [ExtensionDeclSyntax] {
        // Add RawRepresentable conformance.
        let rawRepresentableExtensionDecl = try ExtensionDeclSyntax("extension \(type.trimmed): RawRepresentable") {}

        return [
            rawRepresentableExtensionDecl,
        ]
    }
}

@main
struct RawRepresentableOptionsPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        RawRepresentableOptionsMacro.self,
    ]
}
