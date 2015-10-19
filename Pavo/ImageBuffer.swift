//
//  ImageBuffer.swift
//  Pavo
//
//  Created by Piotr Galar on 01/05/2015.
//  Copyright (c) 2015 Piotr Galar. All rights reserved.
//

import Cocoa
import ImageIO

struct ImageBuffer {

    var capacity: Int

    var images = [CGImage]()
    var current = 0

    init(capacity: Int) {
        self.capacity = capacity
        self.images.reserveCapacity(capacity)
    }

    mutating func add(image: CGImage) {
        if images.count < capacity {
            images.append(image)
        } else {
            images[current] = image
        }
        current = (current + 1) % capacity
    }

    mutating func clear() {
        images.removeAll(keepCapacity: true)
    }

    func toArray() -> [CGImage] {
        var slice = images[current..<images.count]
        slice.appendContentsOf(images[0..<current])
        return Array(slice)
    }

}
