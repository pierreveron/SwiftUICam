<p align="center">
    <img src="https://img.shields.io/badge/platform-iOS%2013%2B-blue.svg?style=flat" alt="Platform: iOS 13.0+"/>
    <a href="https://developer.apple.com/swift"><img src="https://img.shields.io/badge/language-swift%205.1-4BC51D.svg?style=flat" alt="Language: Swift 5.1" /></a>
</p>

# SwiftUICam

If you want to have a custom camera using SwiftUI and not using the UIPickerController that will display the original iOS camera, but don’t have time to play with AVFoundation, this package is for you!

SwiftUICam gives you a simple full screen Snapchat-like Camera View. Then, it is your job to built the interface you want and to connect it to the Camera View.

## Features

|                              | SwiftUICam        
| ------------------------------------- | ---------------------
| :sunglasses:                  | Snapchat-style media capture                              
| :camera:  						  | Image capture               
| :movie_camera:  			      | Video capture                               
| :tada:                        | Front and rear camera support              
| :flashlight:                  | Front and rear flash  
| :sunny:                       | Retina flash support               
| :mag_right:                   |  Supports manual zoom               
| :lock:                        | Supports manual focus

## Requirements

iOS 13.0+

## Credits

It’s inspired by the project SwiftyCam made for UIKit: https://github.com/Awalz/SwiftyCam

## Installation

### Swift Package Manager:

SwiftUICam is available through SPM. To install it, go to `File -> Swift Packages -> Add Package Dependency` 

And enter
```
https://github.com/pierreveron/SwiftUICam
```

As the url.

### Manual installation:

Simply copy the contents of the Source folder into your project.

## Usage

### Prerequisites:

As of iOS 10, Apple requires the additon of the `NSCameraUsageDescription` and `NSMicrophoneUsageDescription` strings to the info.plist of your application. Example:

```xml
<key>NSCameraUsageDescription</key>
	<string>To Take Photos and Video</string>
<key>NSMicrophoneUsageDescription</key>
	<string>To Record Audio With Video</string>
```

### Getting Started:

In your SwiftUI view simply add it in like you would any other view.

Here's an example adding it to a simple view called `ContentView`

```
import SwiftUI
import SwiftUICam

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
              CameraView()
            }
        }
    }
}

```

### Capture

Add an @ObservedObject UserEvents that will be pass to the interface and the CameraViewRepresentable like this:

```
import SwiftUI
import SwiftUICam

struct ContentView: View {
    @ObservedObject events = UserEvents()
    var body: some View {
    	ZStack {
              CameraView(events: events)
	      InterfaceView(events: events)
    	}
    }
}

```

Make your interface view conform to the CameraActions protocol and add the @ObservedObject UserEvents property.
Add gestures to your buttons that call the CameraActions functions and pass them the UserEvents property, simply as that.


## What's next

- Add support for the device orientation
- Add background audio support
- Wait for Apple to release an update of SwiftUI to maybe make it simplier to use AVFoundation
