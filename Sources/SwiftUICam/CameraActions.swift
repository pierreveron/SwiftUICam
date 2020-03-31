//
//  CameraActions.swift
//  SwiftUICam
//
//  Created by Pierre Véron on 31.03.20.
//  Copyright © 2020 Pierre Véron. All rights reserved.
//

import Foundation

public protocol CameraActions {
    func takePhoto()
    func toggleVideoRecording()
    func rotateCamera()
    func changeFlashMode()
}
