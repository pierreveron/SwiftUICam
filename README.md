<p align="center">
    <img src="https://img.shields.io/badge/platform-iOS%2013%2B-blue.svg?style=flat" alt="Platform: iOS 13.0+"/>
    <a href="https://developer.apple.com/swift"><img src="https://img.shields.io/badge/language-swift%205.1-4BC51D.svg?style=flat" alt="Language: Swift 5.1" /></a>
</p>

# SwiftUICam

If you want to have a custom camera using SwiftUI and not using the UIPickerController that will display the original iOS camera, but don’t have time to play with AVFoundation, this package is for you!

SwiftUICam gives you a simple full screen Snapchat-style Camera View. Then, it is your job to built the interface you want and to connect it to the Camera View.

that gives a realtime view of the iPhone camera

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

In your SwiftUI view simply add the CameraView, pass it the applicationName and add an @ObservedObject UserEvents that will be pass to the interface and the CameraViewRepresentable like this:

```
import SwiftUI
import SwiftUICam

struct ContentView: View {
    @ObservedObject events = UserEvents()
    var body: some View {
    	ZStack {
              CameraView(events: events, applicationName: "SwiftUICam")
	      InterfaceView(events: events)
    	}
    }
}

```
## Interface view

Make your interface view conform to the CameraActions protocol and add the @ObservedObject UserEvents property.
Add gestures to your buttons that call the CameraActions functions and pass them the UserEvents property, simply as that.

## Customize the CameraView

You can modify several properties of the CameraView on its initialization:

        - preferredStartingCameraType
        - preferredStartingCameraPosition
        - pinchToZoom
        - tapToFocus
	- focusImage
        - doubleTapCameraSwitch

### TapToFocus

CameraView, by default, support tap to focus on the video preview. To disable this feature, pass the `tapToFocus` property `false`.

#### FocusImage

When tapToFocus is enable, you can pass an image that will be animate on the tap point.

### PinchToZoom

CameraView, by default, support pinchToZoom on the front and back camera. The gestures work similar to the default iOS app and will zoom to the maximum supported zoom level. To disable this feature, pass the `pinchToZoom` property `false`.

### DoubleTapCameraSwitch

By default, CameraView will launch to the back camera. This can be changed by changing the `preferredStartingCameraPosition` to your desired one.

## What's next

- Add support for the device orientation
- Add background audio support
- Wait for Apple to release an update of SwiftUI to maybe make it simplier to use AVFoundation
