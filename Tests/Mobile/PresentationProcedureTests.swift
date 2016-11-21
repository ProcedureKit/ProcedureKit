//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitMobile

public protocol PresentingViewController {

}

public protocol PresentationProcedure {
    associatedtype Presented: UIViewController
    associatedtype Presenting: PresentingViewController
}
