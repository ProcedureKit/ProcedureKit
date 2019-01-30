//
//  ProcedureKit
//
//  Copyright © 2019 ProcedureKit. All rights reserved.
//

import Foundation

public final class EncodeJSONProcedure<T: Encodable>: TransformProcedure<T,Data> {

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

    public init(_ encoder: JSONEncoder) {
        super.init { return try encoder.encode($0) }
    }
}
