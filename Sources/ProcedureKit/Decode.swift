//
//  ProcedureKit
//
//  Copyright © 2019 ProcedureKit. All rights reserved.
//

import Foundation

public final class DecodeJSONProcedure<T: Decodable>: TransformProcedure<Data, T> {

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

    public init(_ decoder: JSONDecoder) {
        super.init { return try decoder.decode(T.self, from: $0) }
    }
}
