//
//  ViewModel.swift
//  ScreenCapture
//
//  Created by Gabriel Echeverria on 13/3/23.
//

import AVFoundation
import Foundation

class ViewModel: ObservableObject {
    // MARK: - Properties
    @Published var showCameraAlert: Bool = false
    @Published var showVideoView: Bool = false
    @Published var selectedScanMode: Int = 0

    // MARK: - Funtionality
    func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            showVideoView.toggle()
        case .denied, .notDetermined:
            requestPermission()
        case .restricted:
            showCameraAlert.toggle()
        @unknown default:
            print("Unknown camera permission: ", status)
        }
    }

    private func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] permission in
            DispatchQueue.main.async {
                if permission {
                    self?.showVideoView.toggle()
                } else {
                    self?.showCameraAlert.toggle()
                }
            }
        }
    }
}
