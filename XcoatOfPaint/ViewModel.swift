//
//  ViewModel.swift
//  XcoatOfPaint
//
//  Created by Christian Lobach on 16.05.21.
//

import Foundation
import Combine

class ViewModel: NSObject {

    @objc private let xcodeManager = XcodeManager()
    @objc private let imageEditor = ImageEditor()

    @objc dynamic private(set) var replaceIconButtonTitle: String = "Replace Xcode icon"

    override init() {
        super.init()
        startObserving()
    }

    private var cancellables = Set<AnyCancellable>()
    private func startObserving() {
        xcodeManager
            .publisher(for: \.appName)
            .map { "Replace \($0) icon" }
            .assign(to: \.replaceIconButtonTitle, on: self)
            .store(in: &cancellables)
    }

    var errorHandler: ((Error) -> Void)?

    func loadApp(at url: URL) {
        xcodeManager.appURL = url
        imageEditor.inputImage = xcodeManager.appIcon
    }

    func replaceIcon() {
        guard let outputImage = imageEditor.outputImage else { return }
        do {
            try xcodeManager.replaceIcon(with: outputImage)
        } catch {
            errorHandler?(error)
        }
    }

    func restoreDefaultIcon() {
        do {
            try xcodeManager.restoreDefaultIcon()
        } catch {
            errorHandler?(error)
        }
    }
}
