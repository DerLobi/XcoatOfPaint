//
//  XcodeManager.swift
//  XcoatOfPaint
//
//  Created by Christian Lobach on 25.04.21.
//

import Cocoa

struct RecoveryAction {
    let title: String
    let action: () -> Void
}

struct XcodeManagerError: LocalizedError {

    fileprivate enum ErrorType {
        case needsToChangeInGetInfo
        case needsToRemoveInGetInfo
        case iconChangeFailed
    }

    fileprivate var errorType: ErrorType

    var recoveryAction: RecoveryAction? = nil

    var failureReason: String? {
        switch errorType {
        case .needsToChangeInGetInfo, .needsToRemoveInGetInfo:
            return "If you have installed Xcode from the App Store, this app doesn't have enough permissions to change the app icon autimatically.\nYou can change or remove the icon manually via the \"Get Info\" dialog."
        default:
            return nil
        }
    }

    var recoverySuggestion: String? {
        switch errorType {
        case .needsToChangeInGetInfo:
            return "Select the existing icon in the top of the \"Xcode Info\" dialog and press ⌘ + V."
        case .needsToRemoveInGetInfo:
            return "Click on the icon in the \"Xcode Info\" dialog and press the delete key on your keyboard."
        default:
            return nil
        }
    }
}

class XcodeManager {

    var xcodeURL: URL?

    var icnsURL: URL? {
        xcodeURL?.appendingPathComponent("Contents/Resources/Xcode.icns")
    }

    func replaceIcon(with image: NSImage) throws {
        guard let xcodeURL = xcodeURL else { return }
        let iconChangeSuccessful = NSWorkspace.shared.setIcon(image,
                                                 forFile: xcodeURL.path,
                                                 options: [])

        if iconChangeSuccessful { return }

        let pasteboard = NSPasteboard.withUniqueName()
        pasteboard.declareTypes([.fileURL], owner: nil)
        (xcodeURL as NSURL).write(to: pasteboard)

        throw XcodeManagerError(errorType: .needsToChangeInGetInfo,
                                recoveryAction: RecoveryAction(title: "Open \"Xcode Info\" dialog") {
            if NSPerformService("Finder/Show Info", pasteboard) {
                let rep = image.tiffRepresentation
                let generalPasteboard = NSPasteboard.general
                generalPasteboard.clearContents()
                generalPasteboard.setData(rep, forType: .tiff)
            }
        })
    }

    func restoreDefaultIcon() throws {
        guard let xcodeURL = xcodeURL else { return }
        let iconChangeSuccessful = NSWorkspace.shared.setIcon(nil,
                                                              forFile: xcodeURL.path,
                                                              options: [])
        if !iconChangeSuccessful {
            let pasteboard = NSPasteboard.withUniqueName()
            pasteboard.declareTypes([.fileURL], owner: nil)
            (xcodeURL as NSURL).write(to: pasteboard)
            throw XcodeManagerError(errorType: .needsToRemoveInGetInfo,
                                    recoveryAction: RecoveryAction(title: "Open \"Xcode Info\" dialog") {
                                        NSPerformService("Finder/Show Info", pasteboard)
                                    })

        }
    }
}
