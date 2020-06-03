//
//  CameraViewController.swift
//  SwiftUICam
//
//  Created by Pierre Véron on 31.03.20.
//  Copyright © 2020 Pierre Véron. All rights reserved.
//  Copyright (c) 2016, Andrew Walz.

/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 The app's primary view controller that presents the camera interface.
 */

import UIKit
import AVFoundation
import Photos

public class PreviewView: UIView {
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
        }
        return layer
    }
    
    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }
    
    override public class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}

public class CameraViewController: UIViewController {
    // MARK: Public Variable Declarations
    
    /// Name of the application using the camera
    public var applicationName: String?
    
    public var preferredStartingCameraType: AVCaptureDevice.DeviceType?
    
    public var preferredStartingCameraPosition: AVCaptureDevice.Position?
    
    /// Public Camera Delegate for the Custom View Controller Subclass
    public var delegate: CameraViewControllerDelegate?
    
    /// Maximum video duration if SwiftyCamButton is used
    public var maximumVideoDuration: Double = 10.0
    
    /// Video capture quality
    public var videoQuality: AVCaptureSession.Preset = .high
    
    /// Flash Mode
    public var flashMode: AVCaptureDevice.FlashMode = .off
    
    /// Sets whether Pinch to Zoom is enabled for the capture session
    public var pinchToZoom = true
    
    /// Sets the maximum zoom scale allowed during gestures gesture
    public var maxZoomScale = CGFloat.greatestFiniteMagnitude
    
    /// Sets whether Tap to Focus and Tap to Adjust Exposure is enabled for the capture session
    public var tapToFocus = true
    
    public var focusImage: String?
    
    /// Sets whether a double tap to switch cameras is supported
    public var doubleTapCameraSwitch = true
    
    /// Sets whether swipe vertically to zoom is supported
    public var swipeToZoom = true
    
    /// Sets whether swipe vertically gestures should be inverted
    public var swipeToZoomInverted = false
    
    /// Set whether SwiftyCam should allow background audio from other applications
    public var allowBackgroundAudio = true
    
    /// Specifies the [videoGravity](https://developer.apple.com/reference/avfoundation/avcapturevideopreviewlayer/1386708-videogravity) for the preview layer.
    public var videoGravity: AVLayerVideoGravity = .resizeAspect
    
    /// Sets whether or not video recordings will record audio
    /// Setting to true will prompt user for access to microphone on View Controller launch.
    public var audioEnabled = true
    
    // MARK: Public Get-only Variable Declarations
    
    /// Returns true if video is currently being recorded
    
    private(set) public var isVideoRecording      = false
    
    /// Returns true if the capture session is currently running
    
    private(set) public var isSessionRunning     = false
    
    // MARK: Private Constant Declarations
    
    /// Current Capture Session
    private let session = AVCaptureSession()
    
    private let sessionQueue = DispatchQueue(label: "session queue")
    
    // MARK: Private Variable Declarations
    
    /// Variable for storing current zoom scale
    private var zoomScale: CGFloat = 1
    
    /// Variable for storing initial zoom scale before Pinch to Zoom begins
    private var beginZoomScale: CGFloat = 1
    
    //    private var setupResult: AVAuthorizationStatus = .authorized
    private var setupResult: SessionSetupResult = .success
    
    /// BackgroundID variable for video recording
    private var backgroundRecordingID: UIBackgroundTaskIdentifier?
    
    private var previewView = PreviewView()
    
    /// Video Input variable
    private var videoDeviceInput: AVCaptureDeviceInput!
    
    /// Movie File Output variable
    private var movieFileOutput: AVCaptureMovieFileOutput?
    
    /// Photo File Output variable
    private var photoOutput: AVCapturePhotoOutput?
    
    /// Video Device variable
    private var videoDevice: AVCaptureDevice?
    
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    /// Boolean to store when View Controller is notified session is running
    private var sessionRunning = false
    
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera], mediaType: .video, position: .unspecified)
    
    // MARK: View Controller Life Cycle
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the video preview view.
        previewView.session = session
        previewView.videoPreviewLayer.videoGravity = videoGravity
        previewView.videoPreviewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        previewView.frame = view.frame
        view.addSubview(previewView)
        
        // Add Gesture Recognizers
        addGestureRecognizers()
        
        /*
         Check the video authorization status. Video access is required and audio
         access is optional. If the user denies audio access, AVCam won't
         record audio during movie recording.
         */
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // The user has previously granted access to the camera.
            break
            
        case .notDetermined:
            /*
             The user has not yet been presented with the option to grant
             video access. Suspend the session queue to delay session
             setup until the access request has completed.
             
             Note that audio access will be implicitly requested when we
             create an AVCaptureDeviceInput for audio during session setup.
             */
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
            
        default:
            // The user has previously denied access.
            setupResult = .notAuthorized
        }
        
        /*
         Setup the capture session.
         In general, it's not safe to mutate an AVCaptureSession or any of its
         inputs, outputs, or connections from multiple threads at the same time.
         
         Don't perform these tasks on the main queue because
         AVCaptureSession.startRunning() is a blocking call, which can
         take a long time. Dispatch session setup to the sessionQueue, so
         that the main queue isn't blocked, which keeps the UI responsive.
         */
        sessionQueue.async {
            self.configureSession()
        }
        
        
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sessionQueue.async {
            switch self.setupResult {
            case .success:
                // Only setup observers and start the session if setup succeeded.
                //                self.addObservers()
                
                // Begin Session
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
                
            case .notAuthorized:
                DispatchQueue.main.async {
                    let changePrivacySetting = "\(self.applicationName!) doesn't have permission to use the camera, please change privacy settings"
                    let message = NSLocalizedString(changePrivacySetting, comment: "Alert message when the user has denied access to the camera")
                    
                    let alertController = UIAlertController(title: self.applicationName!, message: message, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                            style: .cancel,
                                                            handler: nil))
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"),
                                                            style: .`default`,
                                                            handler: { _ in
                                                                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                                                          options: [:],
                                                                                          completionHandler: nil)
                    }))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            case .configurationFailed:
                //                // Unknown Error
                //                DispatchQueue.main.async {
                //                    self.delegate?.swiftyCamDidFailToConfigure(self)
                //                }
                DispatchQueue.main.async {
                    let alertMsg = "Alert message when something goes wrong during capture session configuration"
                    let message = NSLocalizedString("Unable to capture media", comment: alertMsg)
                    let alertController = UIAlertController(title: self.applicationName!, message: message, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                            style: .cancel,
                                                            handler: nil))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
                
            }
        }
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        sessionQueue.async {
            if self.setupResult == .success {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
                //                self.removeObservers()
            }
        }
        
        super.viewWillDisappear(animated)
    }
    
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if let videoPreviewLayerConnection = previewView.videoPreviewLayer.connection {
            let deviceOrientation = UIDevice.current.orientation
            guard let newVideoOrientation = AVCaptureVideoOrientation(rawValue: deviceOrientation.rawValue),
                deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
                    return
            }
            
            videoPreviewLayerConnection.videoOrientation = newVideoOrientation
        }
    }
    
    // MARK: Private Functions
    
    // Call this on the session queue.
    /// - Tag: ConfigureSession
    private func configureSession() {
        if setupResult != .success {
            return
        }
        
        //End configuration
        session.beginConfiguration()
        
        //Preset of the Snapchat Camera is .high
        session.sessionPreset = .high
        //.photo is the preset for normal photo in the iOS camera app
        //      session.sessionPreset = .photo
        
        // Add video input.
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            // Choose the back dual camera, if available, otherwise default to a wide angle camera.
            if let preferredCameraDevice = AVCaptureDevice.default(preferredStartingCameraType!, for: .video, position: preferredStartingCameraPosition!) {
                defaultVideoDevice = preferredCameraDevice
            } else if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                // If a rear dual camera is not available, default to the rear wide angle camera.
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                // If the rear wide angle camera isn't available, default to the front wide angle camera.
                defaultVideoDevice = frontCameraDevice
            }
            guard let videoDevice = defaultVideoDevice else {
                print("Default video device is unavailable.")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                DispatchQueue.main.async {
                    /*
                     Dispatch video streaming to the main queue because AVCaptureVideoPreviewLayer is the backing layer for PreviewView.
                     You can manipulate UIView only on the main thread.
                     Note: As an exception to the above rule, it's not necessary to serialize video orientation changes
                     on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                     
                     Use the window scene's orientation as the initial video orientation. Subsequent orientation changes are
                     handled by CameraViewController.viewWillTransition(to:with:).
                     */
//                    var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                    //                    if self.windowOrientation != .unknown {
                    //                        if let videoOrientation = AVCaptureVideoOrientation(interfaceOrientation: self.windowOrientation) {
                    //                            initialVideoOrientation = videoOrientation
                    //                        }
                    //                    }
                    
//                    self.previewView.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
                }
            } else {
                print("Couldn't add video device input to the session.")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
        } catch {
            print("Couldn't create video device input: \(error)")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        // Add an audio input device.
        do {
            let audioDevice = AVCaptureDevice.default(for: .audio)
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice!)
            
            if session.canAddInput(audioDeviceInput) {
                session.addInput(audioDeviceInput)
            } else {
                print("Could not add audio device input to the session")
            }
        } catch {
            print("Could not create audio device input: \(error)")
        }
        
        // Add the photo output.
        let photoOutput = AVCapturePhotoOutput()
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            self.photoOutput = photoOutput
        } else {
            print("Could not add photo output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        /*
         Do not create an AVCaptureMovieFileOutput when setting up the session because
         Live Photo is not supported when AVCaptureMovieFileOutput is added to the session.
         */
        // Add the photo output here bc we don't support Live Photo
        let movieFileOutput = AVCaptureMovieFileOutput()
        
        if self.session.canAddOutput(movieFileOutput) {
            self.session.addOutput(movieFileOutput)
            
            if let connection = movieFileOutput.connection(with: AVMediaType.video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
            
            self.movieFileOutput = movieFileOutput
        }
        
        //End configuration
        session.commitConfiguration()
    }
    
    private func savePhoto(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(didFinishSavingWithError(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc private func didFinishSavingWithError(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        DispatchQueue.main.async {
            self.delegate?.didFinishSavingWithError(image, error: error, contextInfo: contextInfo)
        }
    }
    
    private func savePhoto(_ photoData: Data) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            
            PHPhotoLibrary.shared().performChanges({
                // Add the captured photo's file data as the main resource for the Photos asset.
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .photo, data: photoData, options: nil)
            }, completionHandler: nil)
        }
    }
    
    // MARK: Public Functions
    
    public func takePhoto() {
        sessionQueue.async {
            let photoSettings = AVCapturePhotoSettings()
            
            if self.videoDeviceInput!.device.isFlashAvailable {
                photoSettings.flashMode = self.flashMode
            }
            
            self.photoOutput?.capturePhoto(with: photoSettings, delegate: self)
        }
    }
    
    public func rotateCamera() {
        sessionQueue.async {
            let currentVideoDevice = self.videoDeviceInput?.device
            let currentPosition = currentVideoDevice?.position
            
            let preferredPosition: AVCaptureDevice.Position
            let preferredDeviceType: AVCaptureDevice.DeviceType
            
            // TODO: check this situation
            switch currentPosition {
            case .unspecified, .none, .front:
                preferredPosition = .back
                preferredDeviceType = .builtInDualCamera
                
            case .back:
                preferredPosition = .front
                preferredDeviceType = .builtInTrueDepthCamera
                
            @unknown default:
                print("Unknown capture position. Defaulting to back, dual-camera.")
                preferredPosition = .back
                preferredDeviceType = .builtInDualCamera
            }
            let devices = self.videoDeviceDiscoverySession.devices
            var newVideoDevice: AVCaptureDevice? = nil
            
            // First, seek a device with both the preferred position and device type. Otherwise, seek a device with only the preferred position.
            if let device = devices.first(where: { $0.position == preferredPosition && $0.deviceType == preferredDeviceType }) {
                newVideoDevice = device
            } else if let device = devices.first(where: { $0.position == preferredPosition }) {
                newVideoDevice = device
            }
            
            if let videoDevice = newVideoDevice {
                do {
                    let captureDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                    
                    self.session.beginConfiguration()
                    
                    // Remove the existing device input first, because AVCaptureSession doesn't support
                    // simultaneous use of the rear and front cameras.
                    self.session.removeInput(self.videoDeviceInput!)
                    // remove and re-add inputs and outputs
                    //                    for input in self.session.inputs {
                    //                        self.session.removeInput(input)
                    //                    }
                    
                    if self.session.canAddInput(captureDeviceInput) {
                        //                        NotificationCenter.default.removeObserver(self, name: .AVCaptureDeviceSubjectAreaDidChange, object: currentVideoDevice)
                        //                        NotificationCenter.default.addObserver(self, selector: #selector(self.subjectAreaDidChange), name: .AVCaptureDeviceSubjectAreaDidChange, object: videoDeviceInput.device)
                        
                        self.session.addInput(captureDeviceInput)
                        self.videoDeviceInput = captureDeviceInput
                    } else {
                        self.session.addInput(self.videoDeviceInput!)
                    }
                    
                    if let connection = self.movieFileOutput?.connection(with: .video) {
                        if connection.isVideoStabilizationSupported {
                            connection.preferredVideoStabilizationMode = .auto
                        }
                    }
                    self.session.commitConfiguration()
                } catch {
                    print("Error occurred while creating video device input: \(error)")
                }
                
            }
            DispatchQueue.main.async {
                self.delegate?.didRotateCamera()
            }
        }
    }
    
    public func changeFlashMode() {
        switch flashMode {
        case .off:
            flashMode = .auto
        case .auto:
            flashMode = .on
        default:
            flashMode = .off
        }
        
        DispatchQueue.main.async {
            self.delegate?.didChangeFlashMode()
        }
    }
    
    public func toggleMovieRecording() {
        guard let movieFileOutput = self.movieFileOutput else {
            return
        }
        print("Hey3")
        
        let videoPreviewLayerOrientation = previewView.videoPreviewLayer.connection?.videoOrientation
        
        sessionQueue.async {
            if !movieFileOutput.isRecording {
                if UIDevice.current.isMultitaskingSupported {
                    self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                }
                
                // Update the orientation on the movie file output video connection before recording.
                let movieFileOutputConnection = movieFileOutput.connection(with: .video)
                movieFileOutputConnection?.videoOrientation = videoPreviewLayerOrientation!
                
                let availableVideoCodecTypes = movieFileOutput.availableVideoCodecTypes
                
                if availableVideoCodecTypes.contains(.hevc) {
                    movieFileOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: movieFileOutputConnection!)
                }
                
                // Start recording video to a temporary file.
                let outputFileName = NSUUID().uuidString
                let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
                movieFileOutput.startRecording(to: URL(fileURLWithPath: outputFilePath), recordingDelegate: self)
            } else {
                movieFileOutput.stopRecording()
            }
        }
    }
    
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    
    /// - Tag: DidFinishCaptureFor
    // Maybe I will change it do willCapturePhotoFor
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        DispatchQueue.main.async {
            // Flash the screen to signal that SwiftUICam took a photo.
            self.view.layer.opacity = 0
            UIView.animate(withDuration: 0.5) {
                self.view.layer.opacity = 1
            }
            self.delegate?.didCapturePhoto()
        }
    }
    
    
    /// - Tag: DidFinishProcessing
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else { print("Error capturing photo: \(error!)"); return }
        
        if let photoData = photo.fileDataRepresentation() {
            let dataProvider = CGDataProvider(data: photoData as CFData)
            let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!,
                                     decode: nil,
                                     shouldInterpolate: true,
                                     intent: CGColorRenderingIntent.defaultIntent)
            
            // TODO: implement imageOrientation
            // Set proper orientation for photo
            // If camera is currently set to front camera, flip image
            //          let imageOrientation = getImageOrientation()
            
            // For now, it is only right
            let image = UIImage(cgImage: cgImageRef!, scale: 1, orientation: .right)
            
            //2 options to save
            //First is to use UIImageWriteToSavedPhotosAlbum
            savePhoto(image)
            //Second is adapting Apple documentation with data of the modified image
            //savePhoto(image.jpegData(compressionQuality: 1)!)
            
            
            DispatchQueue.main.async {
                self.delegate?.didFinishProcessingPhoto(image)
            }
        }
    }
}

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    /// - Tag: DidStartRecording
    public func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        DispatchQueue.main.async {
            self.delegate?.didStartVideoRecording()
        }
    }
    
    /// - Tag: DidFinishRecording
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        // Note: Because we use a unique file path for each recording, a new recording won't overwrite a recording mid-save.
        func cleanup() {
            let path = outputFileURL.path
            if FileManager.default.fileExists(atPath: path) {
                do {
                    try FileManager.default.removeItem(atPath: path)
                } catch {
                    print("Could not remove file at url: \(outputFileURL)")
                }
            }
            
            if let currentBackgroundRecordingID = backgroundRecordingID {
                backgroundRecordingID = UIBackgroundTaskIdentifier.invalid
                
                if currentBackgroundRecordingID != UIBackgroundTaskIdentifier.invalid {
                    UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
                }
            }
        }
        
        DispatchQueue.main.async {
            self.delegate?.didFinishVideoRecording()
        }
        
        var success = true
        
        if error != nil {
            print("Movie file finishing error: \(String(describing: error))")
            success = (((error! as NSError).userInfo[AVErrorRecordingSuccessfullyFinishedKey] as AnyObject).boolValue)!
        }
        
        if success {
            // Check the authorization status.
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    // Save the movie file to the photo library and cleanup.
                    PHPhotoLibrary.shared().performChanges({
                        let options = PHAssetResourceCreationOptions()
                        options.shouldMoveFile = true
                        let creationRequest = PHAssetCreationRequest.forAsset()
                        creationRequest.addResource(with: .video, fileURL: outputFileURL, options: options)
                    }, completionHandler: { success, error in
                        if !success {
                            print("\(self.applicationName!) couldn't save the movie to your photo library: \(String(describing: error))")
                        }
                        cleanup()
                    }
                    )
                } else {
                    cleanup()
                }
            }
        } else {
            cleanup()
        }
    }
}

// MARK: UIGestureRecognizer Declarations
extension CameraViewController {
    
    /// Handle single tap gesture
    @objc func singleTapGesture(tap: UITapGestureRecognizer) {
        guard tapToFocus == true else {
            // Ignore taps
            return
        }
        
        let screenSize = previewView.bounds.size
        let tapPoint = tap.location(in: previewView)
        let x = tapPoint.y / screenSize.height
        let y = 1.0 - tapPoint.x / screenSize.width
        let focusPoint = CGPoint(x: x, y: y)
        
        let device = videoDeviceInput!.device
        
        do {
            try device.lockForConfiguration()
            
            if device.isFocusPointOfInterestSupported == true {
                device.focusPointOfInterest = focusPoint
                device.focusMode = .autoFocus
            }
            device.exposurePointOfInterest = focusPoint
            device.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
            device.unlockForConfiguration()
            //Call delegate function and pass in the location of the touch
            
            DispatchQueue.main.async {
                self.delegate?.didFocusOnPoint(tapPoint)
                self.focusAnimationAt(tapPoint)
            }
        }
        catch {
            // just ignore
        }
    }
    
    /// Handle double tap gesture
    @objc fileprivate func doubleTapGesture(tap: UITapGestureRecognizer) {
        guard doubleTapCameraSwitch == true else {
            // Ignore double taps
            return
        }
        rotateCamera()
    }
    
    /// Handle pinch gesture
    @objc fileprivate func zoomGesture(pinch: UIPinchGestureRecognizer) {
        guard pinchToZoom == true else {
            //ignore pinch
            return
        }
        do {
            let captureDevice = videoDeviceInput?.device
            try captureDevice?.lockForConfiguration()
            
            zoomScale = min(maxZoomScale, max(1.0, min(beginZoomScale * pinch.scale,  captureDevice!.activeFormat.videoMaxZoomFactor)))
            
            captureDevice?.videoZoomFactor = zoomScale
            
            // Call Delegate function with current zoom scale
            DispatchQueue.main.async {
                self.delegate?.didChangeZoomLevel(self.zoomScale)
            }
            
            captureDevice?.unlockForConfiguration()
            
        } catch {
            print("Error locking configuration")
        }
    }
    
    fileprivate func addGestureRecognizers() {
        
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(singleTapGesture(tap:)))
        singleTapGesture.numberOfTapsRequired = 1
        singleTapGesture.delegate = self
        previewView.addGestureRecognizer(singleTapGesture)
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTapGesture(tap:)))
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.delegate = self
        previewView.addGestureRecognizer(doubleTapGesture)
        
        singleTapGesture.require(toFail: doubleTapGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(zoomGesture(pinch:)))
        pinchGesture.delegate = self
        previewView.addGestureRecognizer(pinchGesture)
        
        
        //        panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGesture(pan:)))
        //        panGesture.delegate = self
        //        previewLayer.addGestureRecognizer(panGesture)
    }
}

// MARK: UIGestureRecognizerDelegate
extension CameraViewController : UIGestureRecognizerDelegate {
    
    /// Set beginZoomScale when pinch begins
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isKind(of: UIPinchGestureRecognizer.self) {
            beginZoomScale = zoomScale;
        }
        return true
    }
}

// MARK: UI Animations
extension CameraViewController {
    private func focusAnimationAt(_ point: CGPoint) {
        guard let focusImage = self.focusImage else {
            return
        }
        let image = UIImage(named: focusImage)
        let focusView = UIImageView(image: image)
        focusView.center = point
        focusView.alpha = 0.0
        self.view.addSubview(focusView)
        //      self.previewView.addSubview(focusView)
        
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            focusView.alpha = 1.0
            focusView.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
        }) { (success) in
            UIView.animate(withDuration: 0.15, delay: 0.5, options: .curveEaseInOut, animations: {
                focusView.alpha = 0.0
                focusView.transform = CGAffineTransform(translationX: 0.6, y: 0.6)
            }) { (success) in
                focusView.removeFromSuperview()
            }
        }
    }
}

