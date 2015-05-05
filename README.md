# pavo

Pavo is an OSX framework written in Swift responsible for continuous and
efficient display capture.

### pavo
The framework was named after all the [Peafowls](http://en.wikipedia.org/wiki/Peafowl)
and the wonderful 'display' they have.

### How to include the framework in a project?
1. Clone the Pavo repository
```
git clone https://github.com/gfjalar/pavo.git
```
2. Open the project in XCode and build it
3. In XCode, right click Pavo/Products/Pavo.framework and 'Show in Finder'
4. Drag & drop Pavo.framework in the project
5. Inside the project(General settings) add Pavo.framework to
'Embedded Binaries'

*I found [Haroon Baig's post](https://medium.com/@PyBaig/build-your-own-cocoa-touch-frameworks-in-swift-d4ea3d1f9ca3) very helpful when creating the framework*

### Usage

To import:
```swift
import Pavo
```

To create new monitor:
```swift
// Display monitor constructor takes:
//  duration of the capture session in seconds
//  number of frames captured per second
//  the id of the display to capture
let monitor = DisplayMonitor(duration: 10, fps: 25, display: CGMainDisplayID())
```

To start the continuously capturing the display:
```swift
monitor.start()
```

To stop the session:
```swift
monitor.stop()
```

To get the current state of the capturing session:
```swift
// It will return nil if the session has not been started previously
let frames: [CGImage]? = monitor.takeCaptured()
```

To take a screen shot:
```swift
// It does not require capturing session to be running
let screenShot: CGImage = monitor.takeScreenShot()
```

To clear the buffer holding the state of the capturing session:
```swift
monitor.clearCaptured()
```

### TODO:
* saving CGImages as MP4, WebM
* examples, how it works
