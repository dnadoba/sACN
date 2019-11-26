//
//  Main.swift
//  
//
//  Created by David Nadoba on 17.11.19.
//

import Foundation
import sACN
import QuartzCore
import Network

class RepeatingTimer {
    
    let timeInterval: TimeInterval
    let queue: DispatchQueue
    
    init(timeInterval: TimeInterval, queue: DispatchQueue) {
        self.timeInterval = timeInterval
        self.queue = queue
    }
    
    private lazy var timer: DispatchSourceTimer = {
        let t = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags.strict, queue: queue)
        t.schedule(deadline: .now() + self.timeInterval, repeating: self.timeInterval, leeway: DispatchTimeInterval.milliseconds(0))
        t.setEventHandler(handler: { [weak self] in
            self?.eventHandler?()
        })
        return t
    }()
    
    var eventHandler: (() -> Void)?
    
    private enum State {
        case suspended
        case resumed
    }
    
    private var state: State = .suspended
    
    deinit {
        timer.setEventHandler {}
        timer.cancel()
        /*
         If the timer is suspended, calling cancel without resuming
         triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
         */
        resume()
        eventHandler = nil
    }
    
    func resume() {
        if state == .resumed {
            return
        }
        state = .resumed
        timer.resume()
    }
    
    func suspend() {
        if state == .suspended {
            return
        }
        state = .suspended
        timer.suspend()
    }
}

let client = MulticastConnection(universe: 1)

let timer = RepeatingTimer(timeInterval: 1/40, queue: client.queue)
timer.eventHandler = {
    var data = Data(count: 512)
    let t = CACurrentMediaTime()
    let d = sin(t) * 0.5 + 0.5
    let dim = UInt8(truncatingIfNeeded: Int(d * 256))
    let customData = Data([0, 10, 255, 0, 0, 0, dim, 0, 85, 255, 0, 0, 0, dim, 0, 85, 255, 0, 0, 0, dim])
    data[0..<customData.count] = customData
    client.sendDMXData(Data(data))
}
timer.resume()

// wait until the user presses return
print("press return to quit")
let a = readLine()
print(a as Any)
