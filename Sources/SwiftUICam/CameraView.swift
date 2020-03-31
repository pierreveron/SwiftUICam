//
//  CameraView.swift
//  SwiftUICam
//
//  Created by Pierre Véron on 31.03.20.
//  Copyright © 2020 Pierre Véron. All rights reserved.
//

import SwiftUI

// MARK: CameraView
public struct CameraView: UIViewControllerRepresentable {
    @ObservedObject var events: UserEvents
    //To enable call to updateUIView() on change of UserEvents() bc there is a bug
    class RandomClass { }
    let x = RandomClass()
    
    private var focusImage: String?
    
    public init(events: UserEvents, focusImage: String? = nil) {
        self.events = events
        self.focusImage = focusImage
    }
    
    public func makeUIViewController(context: Context) -> CameraViewController {
        let cameraViewController = CameraViewController()
        cameraViewController.delegate = context.coordinator
        cameraViewController.focusImage = focusImage
        return cameraViewController
    }
    
    public func updateUIViewController(_ cameraViewController: CameraViewController, context: Context) {
        if events.didAskToCapturePhoto {
            cameraViewController.takePhoto()
        }
        
        if events.didAskToRotateCamera {
            cameraViewController.rotateCamera()
        }
        
        if events.didAskToChangeFlashMode {
            cameraViewController.changeFlashMode()
        }
        
        if events.didAskToRecordVideo || events.didAskToStopRecording {
            cameraViewController.toggleMovieRecording()
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: Coordinator
    public class Coordinator: NSObject, CameraViewControllerDelegate {
        
        var parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        public func cameraSessionStarted() {
                print("Camera session started")
            }
            
        public func noCameraDetected() {
                print("No camera detected")
            }
            
        public func didRotateCamera() {
                parent.events.didAskToRotateCamera = false
            }
            
        public func didCapturePhoto() {
                parent.events.didAskToCapturePhoto = false
            }
            
        public func didChangeFlashMode() {
                parent.events.didAskToChangeFlashMode = false
            }
            
        public func didFinishProcessingPhoto(_ image: UIImage) {
                //Not yet implemented
            }
            
        public func didFinishSavingWithError(_ image: UIImage, error: NSError?, contextInfo: UnsafeRawPointer) {
                //Not yet implemented
            }
            
        public func didChangeZoomLevel(_ zoom: CGFloat) {
                print("New zoom value: \(zoom)")
            }
            
        public func didFocusOnPoint(_ point: CGPoint) {
                print("Focus on point \(point) made")
            }
            
        public func didStartVideoRecording() {
                print("Video recording started")
            }
            
        public func didFinishVideoRecording() {
                parent.events.didAskToRecordVideo = false
                parent.events.didAskToStopRecording = false
                print("Video recording finished")
            }
            
        public func didSavePhoto() {
                print("Save photo to library")
            }
            
        public func didChangeMaximumVideoDuration(_ duration: Double) {
        //        parent.events.maximumVideoDuration = duration
                print("Change maximumVideoDuration to \(duration)")
            }
    }
}





