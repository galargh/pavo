//
//  ImageHelpers.swift
//  Pavo
//
//  Created by Piotr Galar on 01/05/2015.
//  Copyright (c) 2015 Piotr Galar. All rights reserved.
//

import Cocoa
import ImageIO
import AVFoundation

public extension CGImage {

    // ADD: async execution, completed callback
    public func saveAsPNG(to dir: String, with name: String) {
        let path = "\(dir)\(name).png"
        let url = CFURLCreateWithFileSystemPath(nil, path, .CFURLPOSIXPathStyle,
            .allZeros)
        let destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1,
            nil)
        CGImageDestinationAddImage(destination, self, nil)
        CGImageDestinationFinalize(destination)
    }

    func toCVPixelBuffer() -> CVPixelBuffer {
        var settings = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]

        var baseAddress = CFDataGetBytePtr(
            CGDataProviderCopyData(CGImageGetDataProvider(self))
        )

        var buffer : Unmanaged<CVPixelBuffer>?

        var status = CVPixelBufferCreateWithBytes( kCFAllocatorDefault,
            CGImageGetWidth(self), CGImageGetHeight(self),
            OSType(kCVPixelFormatType_32ARGB),
            UnsafeMutablePointer<Void>(baseAddress),
            CGImageGetBytesPerRow(self), nil, nil, settings, &buffer
        )

        return buffer!.takeRetainedValue()
    }

}

extension Array {

    // ADD: async execution, completed callback
    func saveAsPNG<T: CGImage>(to dir: String, with name: String) {
        var count = 0
        for t in self {
            let image = t as! CGImage
            image.saveAsPNG(to: dir, with: "\(name)\(count)")
            count++
        }
    }

    // ADD: async execution, completed callback
    func saveAsMPEG4<T: CGImage>(to dir: String, with name: String,
        and fps: Int) {
            let url = NSURL(fileURLWithPath: "\(dir)\(name).mp4")
            let video = AVAssetWriter(URL: url, fileType: AVFileTypeMPEG4,
                error: nil)

            // NOT HANDLED: self.count == 0
            let first = self.first! as! CGImage
            let width = CGImageGetWidth(first)
            let height = CGImageGetHeight(first)

            let settings = [
                AVVideoCodecKey: AVVideoCodecH264,
                AVVideoWidthKey: width,
                AVVideoHeightKey: height,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 20000*1000,
                    AVVideoProfileLevelKey:
                        AVVideoProfileLevelH264HighAutoLevel,
                    AVVideoMaxKeyFrameIntervalKey: 1
                ]
            ]

            let input = AVAssetWriterInput(mediaType: AVMediaTypeVideo,
                outputSettings: settings)
            let adaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: input, sourcePixelBufferAttributes: nil)

            input.expectsMediaDataInRealTime = false

            video.addInput(input)
            video.startWriting()

            video.startSessionAtSourceTime(kCMTimeZero)

            var count = 0

            func isReady() -> Bool {
                return adaptor.assetWriterInput.readyForMoreMediaData
            }

            func getTime() -> CMTime {
                return CMTimeMake(Int64(count), Int32(fps))
            }

            for t in self {
                let buffer = (t as! CGImage).toCVPixelBuffer()
                let time = getTime()
                ExponentialBackoff(isReady, 0.1, 2.0) {
                    adaptor.appendPixelBuffer(buffer, withPresentationTime: time)
                }
                count++
            }

            input.markAsFinished()
            video.endSessionAtSourceTime(getTime())
            video.finishWritingWithCompletionHandler(nil)
    }

}

// ADD: maximum number of backoffs, error closure
func ExponentialBackoff(condition: () -> Bool, base: NSTimeInterval,
    multiplier: NSTimeInterval, closure: () -> ()) {
        var backoff = base
        while !condition() {
            NSRunLoop.currentRunLoop().runUntilDate(
                NSDate(timeIntervalSinceNow: backoff))
            backoff *= multiplier
        }
        closure()
}

public func SaveAsMPEG4(images: [CGImage], to dir: String, with name: String,
    and fps: Int) {
        images.saveAsMPEG4(to: dir, with: name, and: fps)
}

public func SaveAsPNG(images: [CGImage], to dir: String, with name: String) {
    images.saveAsPNG(to: dir, with: name)
}
