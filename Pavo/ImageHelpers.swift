//
//  ImageHelpers.swift
//  Pavo
//
//  Created by Piotr Galar on 01/05/2015.
//  Copyright (c) 2015 Piotr Galar. All rights reserved.
//

import Cocoa
import ImageIO

public extension CGImage {

    public func saveAsPNG(to dir: String, with name: String) {
        let path = "\(dir)\(name).png"
        let url = CFURLCreateWithFileSystemPath(nil, path, .CFURLPOSIXPathStyle,
            .allZeros)
        let destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1,
            nil)
        CGImageDestinationAddImage(destination, self, nil)
        CGImageDestinationFinalize(destination)
    }

}

extension Array {

    func saveAsPNG<T: CGImage>(to dir: String, with name: String) {
        var count = 0
        for t in self {
            let image = t as! CGImage
            image.saveAsPNG(to: dir, with: "\(name)\(count)")
            count++
        }
    }

}

public func SaveAsPNG(images: [CGImage], to dir: String, with name: String) {
    images.saveAsPNG(to: dir, with: name)
}
