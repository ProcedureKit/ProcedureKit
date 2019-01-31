//
//  ProcedureKit
//
//  Copyright © 2019 ProcedureKit. All rights reserved.
//

import Foundation

/// A generic Procedure to perfrom JSON decoding of any Decodable type from Data
public final class DecodeJSONProcedure<T: Decodable>: TransformProcedure<Data, T> {

    /// Convenience initializer which allows optional configuration
    /// of the JSONDecoder. All configurations are optional, with
    /// default arguments of nil. Therefore the default behaviour
    /// is that of JSONDecoder itself.
    ///
    /// - See: `JSONDecoder`
    ///
    /// - Parameters:
    ///   - dateDecodingStrategy: an optional DateDecodingStrategy
    ///   - dataDecodingStrategy: an optional DataDecodingStrategy
    ///   - nonConformingFloatDecodingStrategy: an optional NonConformingFloatDecodingStrategy
    ///   - keyDecodingStrategy: an optional KeyDecodingStrategy
    ///   - userInfo: an optional [CodingUserInfoKey: Any]
    public convenience init(
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = nil,
        dataDecodingStrategy: JSONDecoder.DataDecodingStrategy? = nil,
        nonConformingFloatDecodingStrategy: JSONDecoder.NonConformingFloatDecodingStrategy? = nil,
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy? = nil,
        userInfo: [CodingUserInfoKey: Any]? = nil) {

        let decoder = JSONDecoder()

        if let strategy = dateDecodingStrategy {
            decoder.dateDecodingStrategy = strategy
        }

        if let strategy = dataDecodingStrategy {
            decoder.dataDecodingStrategy = strategy
        }

        if let strategy = nonConformingFloatDecodingStrategy {
            decoder.nonConformingFloatDecodingStrategy = strategy
        }

        if let strategy = keyDecodingStrategy {
            decoder.keyDecodingStrategy = strategy
        }

        if let userInfo = userInfo {
            decoder.userInfo.merge(userInfo) { (_, new) in new }
        }

        self.init(decoder)
    }

    /// Initialize the procedure with a JSONDecoder instance
    ///
    /// - Parameter decoder: the JSONDecoder to use
    public init(_ decoder: JSONDecoder) {
        super.init { return try decoder.decode(T.self, from: $0) }
    }
}
