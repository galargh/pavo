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
            false)
        // TODO: catch
        guard let destination = CGImageDestinationCreateWithURL(url, kUTTypePNG,
            1, nil) else { return }
        CGImageDestinationAddImage(destination, self, nil)
        CGImageDestinationFinalize(destination)
    }

    func toCVPixelBuffer(width: Int, _ height: Int,
        _ pixelFormat: OSType) -> CVPixelBuffer {

            let settings = [
                kCVPixelBufferCGImageCompatibilityKey as String: true,
                kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
            ]

            let baseAddress = UnsafeMutablePointer<Void>(CFDataGetBytePtr(
                CGDataProviderCopyData(CGImageGetDataProvider(self)))
            )

            let bytesPerRow = CGImageGetBytesPerRow(self)

            var buffer : CVPixelBuffer?

            CVPixelBufferCreateWithBytes(kCFAllocatorDefault, width, height,
                pixelFormat, baseAddress, bytesPerRow, nil, nil, settings,
                &buffer
            )

            return buffer!
    }

    func size() -> (Int, Int) {
        return (CGImageGetWidth(self), CGImageGetHeight(self))
    }

}

extension Array where Element:CGImage {

    // ADD: async execution, completed callback
    func saveAsPNG(to dir: String, with name: String) {
        var count = 0
        for image in self {
            image.saveAsPNG(to: dir, with: "\(name)\(count)")
            count++
        }
    }

    // ADD: async execution, completed callback
    func saveAsMPEG4(to dir: String, with name: String, _ fps: Int,
        _ pixelFormat: Int, _ bitRate: Int, _ profileLevel: String) {

            if self.count == 0 {
                return
            }

            let url = NSURL(fileURLWithPath: "\(dir)\(name).mp4")

            // TODO: catch
            let video = try! AVAssetWriter(URL: url, fileType: AVFileTypeMPEG4)

            let (width, height) = self.first!.size()
            let osPixelFormat = OSType(pixelFormat)

            let settings: [String : AnyObject] = [
                AVVideoCodecKey: AVVideoCodecH264,
                AVVideoWidthKey: width,
                AVVideoHeightKey: height,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: bitRate,
                    AVVideoProfileLevelKey: profileLevel,
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

            for image in self {
                let buffer = image.toCVPixelBuffer(width, height, osPixelFormat)
                let time = getTime()
                ExponentialBackoff(isReady, base: 0.1, multiplier: 2.0) {
                    adaptor.appendPixelBuffer(buffer,
                        withPresentationTime: time)
                }
                count++
            }

            input.markAsFinished()
            video.endSessionAtSourceTime(getTime())
            video.finishWritingWithCompletionHandler({})
    }

}

extension Dictionary {
    func get(key: Key, or defaultValue: Value) -> Value {
        if let value = self[key] {
            return value
        }
        return defaultValue
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
    fps: Int,
    _ pixelFormat: Int = Int(kCVPixelFormatType_32BGRA),
    _ bitRate: Int = 20000*1000,
    _ profileLevel: String = AVVideoProfileLevelH264HighAutoLevel) {
        images.saveAsMPEG4(to: dir, with: name, fps, pixelFormat, bitRate,
            profileLevel)
}

public func SaveAsPNG(images: [CGImage], to dir: String, with name: String) {
    images.saveAsPNG(to: dir, with: name)
}
