//
//  FileDropImageView.swift
//  XcoatOfPaint
//
//  Created by Christian Lobach on 25.04.21.
//

import AppKit


class FileDropImageView: NSImageView {

    var didReceiveFile: ((URL) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([.fileURL])
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if NSURL(from: sender.draggingPasteboard) != nil {
            return .copy
        }
        return []
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        guard let fileURL = NSURL(from: sender.draggingPasteboard) else { return }

        didReceiveFile?(fileURL as URL)
    }
}
