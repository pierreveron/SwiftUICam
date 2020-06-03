<p align="center">
    <img src="https://img.shields.io/badge/platform-iOS%2013%2B-blue.svg?style=flat" alt="Platform: iOS 13.0+"/>
    <a href="https://developer.apple.com/swift"><img src="https://img.shields.io/badge/language-swift%205.1-4BC51D.svg?style=flat" alt="Language: Swift 5.1" /></a>
</p>

# SwiftUICam

If you want to have a custom camera using SwiftUI and not using the UIPickerController that will display the original iOS camera, but don’t have time to play with AVFoundation, this package is for you!

SwiftUICam gives you a realtime full screen Snapchat-style view of the iPhone camera. Then, it is your job to built the interface you want and to connect it to the Camera View.

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

## License

This software is released under the MIT License, see LICENSE.txt.

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

```swift
import SwiftUI
import SwiftUICam

struct ContentView: View {
    @ObservedObject events = UserEvents()
    var body: some View {
    	ZStack {
              CameraView(events: events, applicationName: "SwiftUICam")
	      CameraInterfaceView(events: events)
    	}
    }
}

```

## Interface view

Make your interface view conform to the CameraActions protocol and add the @ObservedObject UserEvents property.
Add gestures to your buttons that call the CameraActions functions and pass them the UserEvents property, simply as that.
```swift
import SwiftUI
import SwiftUICam

struct CameraInterfaceView: View, CameraActions {    
    @ObservedObject var events: UserEvents
    
    var body: some View {
        VStack {
            HStack {
                rotateButton().onTapGesture {
                    self.rotateCamera(events: events)
                }
                Spacer()
                flashButton().onTapGesture {
                    self.changeFlashMode(events: events)
                }
            }
            Spacer()
            captureButton().onTapGesture {
                self.takePhoto(events: events)
            }
        }
    }
}
```

### CameraActions

It is the protocol that order the camera to take a picture or change the flash mode. List of the methods:

```swift
func takePhoto(events: UserEvents)
func toggleVideoRecording(events: UserEvents)
func rotateCamera(events: UserEvents)
func changeFlashMode(events: UserEvents)
```

The methods have a default definition to take make it easy to use.

## Customize the CameraView

You can modify several properties of the CameraView on its initialization:
```swift
init(events: UserEvents, applicationName: String, preferredStartingCameraType: AVCaptureDevice.DeviceType = .builtInWideAngleCamera, preferredStartingCameraPosition: AVCaptureDevice.Position = .back, focusImage: String? = nil, pinchToZoom: Bool = true, tapToFocus: Bool = true, doubleTapCameraSwitch: Bool = true)
```
- preferredStartingCameraType
- preferredStartingCameraPosition
- tapToFocus
- focusImage
- pinchToZoom
- doubleTapCameraSwitch

### Preferred Starting Options

By default, CameraView will launch to the back wide angle camera if it is available. This can be changed by changing the `preferredStartingCameraType` and the `preferredStartingCameraPosition`properties to your desired ones.

### TapToFocus

CameraView, by default, support tap to focus on the video preview. To disable this feature, pass to the `tapToFocus` property `false`.

#### FocusImage

When tapToFocus is enable, you can pass an UIImage that will be animate on the tap point.

### PinchToZoom

CameraView, by default, support pinchToZoom on the front and back camera. The gestures work similar to the default iOS app and will zoom to the maximum supported zoom level. To disable this feature, pass to the `pinchToZoom` property `false`.

### DoubleTapCameraSwitch

CameraView, by default, support double tap to switch camera. To disable this feature, pass to the `doubleTapCameraSwitch` property `false`.

## What's next

- Give more access to customization (max video duration, video quality, ...)
- Add support for the device orientation
- Add background audio support
- Wait for Apple to release an update of SwiftUI to maybe make it simplier to use AVFoundation
