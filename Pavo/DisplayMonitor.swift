//
//  DisplayMonitor.swift
//  Pavo
//
//  Created by Piotr Galar on 01/05/2015.
//  Copyright (c) 2015 Piotr Galar. All rights reserved.
//

import Cocoa
import ImageIO

public class DisplayMonitor {

    var buffer: ImageBuffer
    let interval: NSTimeInterval
    let display: CGDirectDisplayID

    var timer: NSTimer?

    public init(duration: Int = 1, fps: Int = 1, display: CGDirectDisplayID =
        CGMainDisplayID()) {
            buffer = ImageBuffer(capacity: duration * fps)
            interval = 1.0 / Double(fps)
            self.display = display
    }

    public func start() -> Bool {
        if timer != nil {
            return false
        }
        timer = NSTimer.scheduledTimerWithTimeInterval(interval, target: self,
            selector: Selector("capture"), userInfo: nil, repeats: true)
        return true
    }

    public func stop() -> Bool {
        if let t = timer {
            t.invalidate()
            timer = nil
            return true
        }
        return false
    }

    public func takeCaptured() -> [CGImage]? {
        var copy: ImageBuffer?
        sync {
            copy = self.buffer
        }
        return copy?.toArray()
    }

    public func takeScreenShot() -> CGImage {
        return CGDisplayCreateImage(display).takeRetainedValue()
    }

    @objc func capture() {
        sync {
            self.buffer.add(self.takeScreenShot())
        }
    }

    func sync(closure: () -> ()) {
        objc_sync_enter(self)
        closure()
        objc_sync_exit(self)
    }

}
