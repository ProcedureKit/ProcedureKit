//
//  ProcedureKit
//
//  Copyright © 2015-2019 ProcedureKit. All rights reserved.
//

import Foundation
import CoreData


extension TestEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TestEntity> {
        return NSFetchRequest<TestEntity>(entityName: "TestEntity")
    }

    @NSManaged public var identifier: String?
    @NSManaged public var name: String?

}
