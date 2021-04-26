//
//  ViewController.swift
//  XcoatOfPaint
//
//  Created by Christian Lobach on 25.04.21.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet private weak var sourceImageView: FileDropImageView!

    private let xcodeManager = XcodeManager()
    @objc private let imageEditor = ImageEditor()

    override func viewDidLoad() {
        super.viewDidLoad()

        sourceImageView.didReceiveFile = { [weak self] fileURL in
            self?.xcodeManager.xcodeURL = fileURL
            self?.imageEditor.inputImage = self?.xcodeManager.xcodeIcon
        }
    }

    @IBAction private func replaceIcon(_ sender: Any) {
        guard let outputImage = imageEditor.outputImage else { return }
        do {
            try xcodeManager.replaceIcon(with: outputImage)
        } catch {
            handleError(error)
        }
    }

    @IBAction private func restoreDefaultIcon(_ sender: Any) {
        do {
            try xcodeManager.restoreDefaultIcon()
        } catch {
            handleError(error)
        }
    }

    private func handleError(_ error: Error) {
        guard let window = view.window else { return }
        let nsError = error as NSError
        let alert = NSAlert()
        alert.messageText = nsError.localizedFailureReason ?? nsError.localizedDescription
        alert.informativeText = nsError.localizedRecoverySuggestion ?? ""

        let recoveryAction = (error as? XcodeManagerError)?.recoveryAction
        if let recoveryAction = recoveryAction {
            alert.addButton(withTitle: recoveryAction.title)
            alert.addButton(withTitle: "Cancel")
        }

        alert.beginSheetModal(for: window) { response in
            if response == .alertFirstButtonReturn {
                recoveryAction?.action()
            }
        }
    }
}
