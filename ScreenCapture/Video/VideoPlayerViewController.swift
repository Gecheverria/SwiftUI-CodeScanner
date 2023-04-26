//
//  VideoPlayerViewController.swift
//  ScreenCapture
//
//  Created by Gabriel Echeverria on 13/3/23.
//

import AVFoundation
import Combine
import UIKit

// Enum to define the code type we want to scan
enum ScanMode: Int {
    case qr = 0
    case barcode

    var metadataObjectTypes: [AVMetadataObject.ObjectType] {
        switch self {
        case .qr:
            return [.qr]
        case .barcode:
            return [.pdf417, .ean8, .ean13]
        }
    }
}

class VideoPlayerViewModel: ObservableObject {
    // Input
    @Published var scanArea: CGRect = .zero
    @Published var scanMode: ScanMode = .qr
    @Published var pauseScan: Bool = false
    @Published var captureArea: Void = ()

    // Output
    @Published var scannedData: String?
}

class VideoPlayerViewController: UIViewController {
    // MARK: - Properties
    private let viewModel: VideoPlayerViewModel

    private var cancellables: Set<AnyCancellable> = []

    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?

    // MARK: - Init methods
    init(viewModel: VideoPlayerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        configureVideoLayer()
        configureSubscriptions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let session = captureSession, !session.isRunning {
            captureSession?.startRunning()
        }
    }
    

    // MARK: - Configuration
    private func configureVideoLayer() {
        // Check for authorization status
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        guard status == .authorized else { return }

        let captureSession = AVCaptureSession()

        // Start batch multiple configuration operations on a running session into an atomic update.
        captureSession.beginConfiguration()

        // Define the device input and add it into the capture session
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              captureSession.canAddInput(videoInput) else {
            // Show alert
            return
        }
        captureSession.addInput(videoInput)

        // Configure the layer in which the video will be shown
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        self.previewLayer = previewLayer
        self.captureSession = captureSession

        // Commit changes
        captureSession.commitConfiguration()
    }

    private func configureScanArea(rect :CGRect) {
        guard let captureSession, let previewLayer else { return }

        // Begin new configuration changes
        captureSession.beginConfiguration()

        if !captureSession.outputs.isEmpty {
            for output in captureSession.outputs {
                // Remove the old output of the current selection
                captureSession.removeOutput(output)
            }
        }

        let metadataOutput = AVCaptureMetadataOutput()

        guard captureSession.canAddOutput(metadataOutput) else {
            captureSession.commitConfiguration()
            return
        }

        captureSession.addOutput(metadataOutput)

        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)

        for objectType in viewModel.scanMode.metadataObjectTypes {
            guard metadataOutput.availableMetadataObjectTypes.contains(objectType) else { return }
        }

        // Set Meta data types of the selected mode
        metadataOutput.metadataObjectTypes = viewModel.scanMode.metadataObjectTypes

        captureSession.commitConfiguration()

        // Set rect of interest
        let rectOfInterest = CGRect(x: 0.05, y: 0.29, width: 0.9, height: 0.42)

        // metadataOutput.rectOfInterest = rectOfInterest
    }

    private func configureSubscriptions() {
        viewModel.$scanArea
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rect in
                print("WILLSET FRAME: ", rect)
                self?.configureScanArea(rect: rect)
            }
            .store(in: &cancellables)

        viewModel.$pauseScan
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shouldPause in
                guard let self, let session = self.captureSession else { return }

                if shouldPause, session.isRunning {
                    session.stopRunning()
                } else if !session.isRunning {
                    session.startRunning()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension VideoPlayerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
                  let stringValue = readableObject.stringValue else { return }

            // Pause session
            viewModel.scannedData = stringValue
            print(stringValue)
        }
    }
}
