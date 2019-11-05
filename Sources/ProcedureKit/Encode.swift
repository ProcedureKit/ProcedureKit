//
//  ProcedureKit
//
//  Copyright © 2019 ProcedureKit. All rights reserved.
//

import Foundation

/// A generic Procedure to perfrom JSON encoding of any Encodable type to Data
public final class EncodeJSONProcedure<T: Encodable>: TransformProcedure<T,Data> {

    /// Convenience initializer which allows optional configuration
    /// of the JSONEncoder. All configurations are optional, with
    /// default arguments of nil. Therefore the default behaviour
    /// is that of JSONEncoder itself.
    ///
    /// - See: `JSONEncoder`
    ///
    /// - Parameters:
    ///   - dateDecodingStrategy: an optional DateDecodingStrategy
    ///   - dataDecodingStrategy: an optional DataDecodingStrategy
    ///   - nonConformingFloatDecodingStrategy: an optional NonConformingFloatDecodingStrategy
    ///   - keyDecodingStrategy: an optional KeyDecodingStrategy
    ///   - userInfo: an optional [CodingUserInfoKey: Any]
    public convenience init(
        dateEncodingStrategy: JSONEncoder.DateEncodingStrategy? = nil,
        dataEncodingStrategy: JSONEncoder.DataEncodingStrategy? = nil,
        nonConformingFloatEncodingStrategy: JSONEncoder.NonConformingFloatEncodingStrategy? = nil,
        keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy? = nil,
        userInfo: [CodingUserInfoKey: Any]? = nil) {

        let encoder = JSONEncoder()

        if let strategy = dateEncodingStrategy {
            encoder.dateEncodingStrategy = strategy
        }

        if let strategy = dataEncodingStrategy {
            encoder.dataEncodingStrategy = strategy
        }

        if let strategy = nonConformingFloatEncodingStrategy {
            encoder.nonConformingFloatEncodingStrategy = strategy
        }

        if let strategy = keyEncodingStrategy {
            encoder.keyEncodingStrategy = strategy
        }

        if let userInfo = userInfo {
            encoder.userInfo.merge(userInfo) { (_, new) in new }
        }

        self.init(encoder)
    }

    /// Initialize the procedure with a JSONEncoder instance
    ///
    /// - Parameter encoder: the JSONEncoder to use
    public init(_ encoder: JSONEncoder) {
        super.init { return try encoder.encode($0) }
    }
}
