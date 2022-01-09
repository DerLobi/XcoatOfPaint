//
//  ViewController.swift
//  XcoatOfPaint
//
//  Created by Christian Lobach on 25.04.21.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet private weak var sourceImageView: FileDropImageView!

    @objc private let viewModel = ViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        sourceImageView.didReceiveFile = { [weak self] fileURL in
            self?.viewModel.loadApp(at: fileURL)
        }

        viewModel.errorHandler = { [weak self] error in
            self?.handleError(error)
        }
    }

    @IBAction private func replaceIcon(_ sender: Any) {
        viewModel.replaceIcon()
    }

    @IBAction func saveDocument(_ sender: Any) {
        viewModel.saveIcon()
    }

    @IBAction private func restoreDefaultIcon(_ sender: Any) {
        viewModel.restoreDefaultIcon()
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
