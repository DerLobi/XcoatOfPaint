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
        case needsToChangeInGetInfo(appName: String)
        case needsToRemoveInGetInfo(appName: String)
        case iconChangeFailed(appName: String)
    }

    fileprivate var errorType: ErrorType

    var recoveryAction: RecoveryAction?

    var failureReason: String? {
        switch errorType {
        case .needsToChangeInGetInfo, .needsToRemoveInGetInfo:
            // swiftlint:disable line_length
            return """
                If you have installed Xcode from the App Store, this app doesn't have enough permissions to change the app icon automatically.
                You can change or remove the icon manually via the \"Get Info\" dialog.
                """
        // swiftlint:enable line_length
        default:
            return nil
        }
    }

    var recoverySuggestion: String? {
        switch errorType {
        case .needsToChangeInGetInfo(let appName):
            return "Select the existing icon in the top of the \"\(appName) Info\" dialog and press ⌘ + V."
        case .needsToRemoveInGetInfo(let appName):
            return "Click on the icon in the \"\(appName) Info\" dialog and press the delete key on your keyboard."
        default:
            return nil
        }
    }
}

class XcodeManager: NSObject {

    @objc dynamic var appURL: URL? {
        didSet {
            guard var name = appURL?.lastPathComponent, name.hasSuffix(".app") else {
                appName = "Xcode"
                return
            }
            name.removeLast(4)
            appName = name
        }
    }

    @objc dynamic private(set) var appName: String = "Xcode"

    var appIcon: NSImage? {
        guard let xcodeURL = appURL else { return nil }
        return icon(["Xcode", "XcodeBeta", "AppIcon", "AppIconBeta", "Instruments", "InstrumentsBeta"], fromAssetCatalogRelativeToURL: xcodeURL)
            ?? iconFromICNS(["Xcode.icns",
                             "XcodeBeta.icns",
                             "AppIcon.icns",
                             "AppIconBeta.icns",
                             "Instruments.icns",
                             "InstrumentsBeta"
                            ], relativeToURL: xcodeURL)
    }

    private func iconFromICNS(_ icnsFiles: [String], relativeToURL url: URL) -> NSImage? {
        let icnsURLs = icnsFiles.map({ url.appendingPathComponent("Contents/Resources/\($0)") })
        let data = icnsURLs.compactMap { try? Data(contentsOf: $0) }.first
        let image = data.flatMap(NSImage.init(data:))
        return image
    }

    private func icon(_ imageSetNames: [String], fromAssetCatalogRelativeToURL url: URL) -> NSImage? {
        let path = url.appendingPathComponent("Contents/Resources/Assets.car").path
        let catalog = try? AssetsCatalog(path: path)
        let imageSet = catalog?.imageSets.first(where: { imageSetNames.contains($0.name) })
        let mutableData = NSMutableData()

        guard let bestImage = imageSet?.namedImages
                .sorted(by: { $0.size.width * CGFloat($0.scale) > $1.size.width * CGFloat($1.scale) })[1],
              let cgImage = bestImage
                ._rendition()
                .unslicedImage()?
                .takeUnretainedValue(),
              let destination = CGImageDestinationCreateWithData(mutableData as CFMutableData,
                                                                 kUTTypePNG,
                                                                 1,
                                                                 nil)
        else { return nil}
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }

        let nsImage = NSImage(data: mutableData as Data)
        return nsImage
    }

    func replaceIcon(with image: NSImage) throws {
        guard let appURL = appURL else { return }
        let iconChangeSuccessful = NSWorkspace.shared.setIcon(image,
                                                              forFile: appURL.path,
                                                              options: [])
        if iconChangeSuccessful { return }

        let pasteboard = NSPasteboard.withUniqueName()
        pasteboard.declareTypes([.fileURL], owner: nil)
        (appURL as NSURL).write(to: pasteboard)

        throw XcodeManagerError(errorType: .needsToChangeInGetInfo(appName: appName),
                                recoveryAction: RecoveryAction(title: "Open \"\(appName) Info\" dialog") {
                                    if NSPerformService("Finder/Show Info", pasteboard) {
                                        let rep = image.tiffRepresentation
                                        let generalPasteboard = NSPasteboard.general
                                        generalPasteboard.clearContents()
                                        generalPasteboard.setData(rep, forType: .tiff)
                                    }
                                })
    }

    func restoreDefaultIcon() throws {
        guard let appURL = appURL else { return }
        let iconChangeSuccessful = NSWorkspace.shared.setIcon(nil,
                                                              forFile: appURL.path,
                                                              options: [])
        if iconChangeSuccessful { return }

        let pasteboard = NSPasteboard.withUniqueName()
        pasteboard.declareTypes([.fileURL], owner: nil)
        (appURL as NSURL).write(to: pasteboard)

        throw XcodeManagerError(errorType: .needsToRemoveInGetInfo(appName: appName),
                                recoveryAction: RecoveryAction(title: "Open \"\(appName) Info\" dialog") {
                                    NSPerformService("Finder/Show Info", pasteboard)
                                })
    }

}
