//
//  VideoPlayerRepresentable.swift
//  ScreenCapture
//
//  Created by Gabriel Echeverria on 7/4/23.
//

import Foundation
import SwiftUI

struct VideoPlayerRepresentable: UIViewControllerRepresentable {
    let viewModel: VideoPlayerViewModel

    func makeUIViewController(context: Context) -> some UIViewController {
        VideoPlayerViewController(viewModel: viewModel)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {

    }
}
