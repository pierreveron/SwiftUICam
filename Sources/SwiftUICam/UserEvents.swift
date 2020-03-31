//
//  UserEvents.swift
//  SwiftUICam
//
//  Created by Pierre Véron on 31.03.20.
//  Copyright © 2020 Pierre Véron. All rights reserved.
//
import SwiftUI

public class UserEvents: ObservableObject {
    @Published public var didAskToCapturePhoto = false
    @Published public var didAskToRotateCamera = false
    @Published public var didAskToChangeFlashMode = false
    
    @Published public var didAskToRecordVideo = false
    @Published public var didAskToStopRecording = false
    
    public init() {
        
    }
}
