//
//  ContentView.swift
//  ScreenCapture
//
//  Created by Gabriel Echeverria on 9/3/23.
//

import SwiftUI

struct ContentView: View {
    // MARK: - Properties
    @StateObject var viewModel = ViewModel()
    @StateObject var scanViewModel = VideoPlayerViewModel()

    @State private var showScannedData = false
    @State private var scanGeometry: GeometryProxy?

    // MARK: - Main View
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                videoView

                mainOverlayView

                segmentedControlView
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.checkCameraPermission()
            }
            .onChange(of: viewModel.selectedScanMode) { scanMode in
                scanViewModel.scanMode = .init(rawValue: scanMode) ?? .qr
            }
            .alert("Camera permission is not granted", isPresented: $viewModel.showCameraAlert) {
                Button("OK", role: .cancel) { }
            }
        }
        .alert(scanViewModel.scannedData ?? "N/A", isPresented: $showScannedData) {
            Button("OK", role: .cancel) { }
        }
        .onChange(of: scanViewModel.scannedData) { _ in
            guard !showScannedData else { return }

            showScannedData = true
        }
    }

    // MARK: - Overlays
    private var videoView: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray)

            // Add VideoPlayer Representable if permission is granted
            if viewModel.showVideoView {
                VideoPlayerRepresentable(viewModel: scanViewModel)
            }
        }
        .ignoresSafeArea()
    }

    private var mainOverlayView: some View {
        GeometryReader { geometry in
            ZStack {
                // This is the main dark rectangle that will add opacity to the view
                Rectangle()
                    .fill(
                        Color.black
                            .opacity(0.5)
                    )
                    .ignoresSafeArea()

                // This rectangle is the one that will create the "window" inside our dark rectangle
                RoundedRectangle(cornerRadius: 15.0, style: .continuous)
                    .size(width: geometry.size.width * 0.9,
                          height: viewModel.selectedScanMode == 1 ? geometry.size.height * 0.25 : geometry.size.width * 0.9
                    )
                    .blendMode(.destinationOut)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .size(width: geometry.size.width * 0.9,
                                  height: viewModel.selectedScanMode == 1 ? geometry.size.height * 0.25 : geometry.size.width * 0.9
                                 )
                            .stroke(.white, lineWidth: 2.5)
                    )
                    .position(x: overlayRectXPosition(from: geometry), y: overlayRectYPosition(from: geometry))
                    .animation(.linear, value: viewModel.selectedScanMode)
                    // Add listener to the geometry size change so we can update the rect area
                    .onChange(of: geometry.size) { _ in
                        updateScanArea(with: geometry)
                    }
                    .onChange(of: viewModel.selectedScanMode) { _ in
                        updateScanArea(with: geometry)
                    }
            }
            // Use composition view to "carve" out the hole with `.blendMode`
            .compositingGroup()
        }
        .ignoresSafeArea()
    }

    private var segmentedControlView: some View {
        VStack {
            Picker("Scan Mode", selection: $viewModel.selectedScanMode) {
                Text("QR").tag(0)

                Text("Barcode").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top)

            Spacer()
        }
    }

    // MARK: - Helpers
    private func updateScanArea(with geometry: GeometryProxy) {
        // This sends the updated rect bounds to be used by the camera view representable
        scanViewModel.scanArea = CGRect(x: overlayRectXPosition(from: geometry),
                                    y: overlayRectYPosition(from: geometry),
                                    width: geometry.size.width * 0.9,
                                    height: viewModel.selectedScanMode == 1 ? geometry.size.height * 0.25 : geometry.size.width * 0.9)
    }

    private func overlayRectXPosition(from proxy: GeometryProxy) -> CGFloat {
        let center = proxy.frame(in: .global).midX
        let padding = (proxy.size.width * 0.1) / 2

        return center + padding
    }

    private func overlayRectYPosition(from proxy: GeometryProxy) -> CGFloat {
        let center = proxy.frame(in: .global).midY
        let offset = viewModel.selectedScanMode == 1 ? 1.75 : 1.60

        return center * offset
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
