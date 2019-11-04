//
//  ProcedureKit
//
//  Copyright © 2015-2019 ProcedureKit. All rights reserved.
//

import Foundation
import CoreData

@available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *)
extension TestEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TestEntity> {
        return NSFetchRequest<TestEntity>(entityName: "TestEntity")
    }

    @NSManaged public var identifier: String?
    @NSManaged public var name: String?

}
