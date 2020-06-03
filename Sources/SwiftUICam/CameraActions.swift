//
//  CameraActions.swift
//  SwiftUICam
//
//  Created by Pierre Véron on 31.03.20.
//  Copyright © 2020 Pierre Véron. All rights reserved.
//

import Foundation

public protocol CameraActions {
    func takePhoto(events: UserEvents)
    func toggleVideoRecording(events: UserEvents)
    func rotateCamera(events: UserEvents)
    func changeFlashMode(events: UserEvents)
}

public extension CameraActions {
    func takePhoto(events: UserEvents) {
        events.didAskToCapturePhoto = true
    }
    
    func toggleVideoRecording(events: UserEvents) {
        if events.didAskToRecordVideo {
            events.didAskToStopRecording = true
        } else {
            events.didAskToRecordVideo = true
        }
    }
    
    func rotateCamera(events: UserEvents) {
        events.didAskToRotateCamera = true
    }
    
    func changeFlashMode(events: UserEvents) {
        events.didAskToChangeFlashMode = true
    }
}
