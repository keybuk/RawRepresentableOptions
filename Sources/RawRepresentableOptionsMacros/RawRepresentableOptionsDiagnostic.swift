//
//  RawRepresentableOptionsDiagnostic.swift
//  RawRepresentableOptions
//
//  Created by Scott James Remnant on 10/7/26.
//

import SwiftDiagnostics

enum RawRepresentableOptionsDiagnostic {
    case onlyApplicableToStruct
    case requiresMemberEnum
    case requiresEnumRawValueType
}

extension RawRepresentableOptionsDiagnostic: DiagnosticMessage {
    var message: String {
        switch self {
        case .onlyApplicableToStruct: "@RawRepresentableOptions can only be applied to a struct"
        case .requiresMemberEnum: "@RawRepresentableOptions requires an Options member enum"
        case .requiresEnumRawValueType: "@RawRepresentableOptions requires member enum inherit from type for RawValue"
        }
    }

    var severity: DiagnosticSeverity {
        switch self {
        case .onlyApplicableToStruct: .error
        case .requiresMemberEnum: .error
        case .requiresEnumRawValueType: .error
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "RawRepresentableOptions", id: "RawRepresentableOptions.\(self)")
    }
}
