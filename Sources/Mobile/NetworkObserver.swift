//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

protocol NetworkActivityIndicatorProtocol {
    var networkActivityIndicatorVisible: Bool { get set }
}

extension UIApplication: NetworkActivityIndicatorProtocol { }

class NetworkActivityController {

    class Timer {
        let workItem: DispatchWorkItem
        init(interval: TimeInterval, workItem: DispatchWorkItem) {
            self.workItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: workItem)
        }

        convenience init(interval: TimeInterval, block: @escaping () -> Void) {
            self.init(interval: interval, workItem: DispatchWorkItem(block: block))
        }

        func cancel() {
            workItem.cancel()
        }
    }

    static let shared = NetworkActivityController()

    let interval: TimeInterval
    var indicator: NetworkActivityIndicatorProtocol

    var count = 0
    var timer: Timer?

    init(timerInterval: TimeInterval = 1.0, indicator: NetworkActivityIndicatorProtocol = UIApplication.shared) {
        self.interval = timerInterval
        self.indicator = indicator
    }

    func start() {
        count += 1
        update()
    }

    func stop() {
        count -= 1
        update()
    }

    func update() {
        if count > 0 {
            updateIndicator(withVisibility: true)
        }
        else if count == 0 {
            timer = Timer(interval: interval) {
                self.updateIndicator(withVisibility: false)
            }
        }
    }

    func updateIndicator(withVisibility visibility: Bool) {
        timer?.cancel()
        timer = nil
        DispatchQueue.main.async {
            self.indicator.networkActivityIndicatorVisible = visibility
        }
    }
}

public class NetworkObserver: ProcedureObserver {

    private let networkActivityController: NetworkActivityController

    init(controller: NetworkActivityController) {
        networkActivityController = controller
    }

    public convenience init() {
        self.init(controller: NetworkActivityController.shared)
    }

    public func will(execute procedure: Procedure) {
        networkActivityController.start()
    }

    public func did(finish procedure: Procedure, withErrors errors: [Error]) {
        networkActivityController.stop()
    }
}
