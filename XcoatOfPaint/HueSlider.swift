//
//  HueSlider.swift
//  XcoatOfPaint
//
//  Created by Christian Lobach on 25.04.21.
//

import AppKit

extension NSGradient {
    static var allHues: NSGradient = {
        let colors = Array(0...100)
            .map { NSColor(calibratedHue: CGFloat($0) / 100, saturation: 1.0, brightness: 1.0, alpha: 1.0) }
        return NSGradient(colors: colors)!
    }()
}

public class HueSlider: NSSlider {

    private var barGradient: NSGradient = .allHues

    private let bezelXMargin: CGFloat = 6
    private let bezelyMargin: CGFloat = 12


    override public func draw(_ dirtyRect: NSRect) {
        assert(!self.isVertical)

        let bezelFrame = bounds.insetBy(dx: bezelXMargin, dy: bezelyMargin)
        let bar = NSBezierPath(roundedRect: bezelFrame, xRadius: bezelFrame.height * 0.5, yRadius: bezelFrame.height * 0.5)
        barGradient.draw(in: bar, angle: 0.0)

        let innerRect = bounds.insetBy(dx: 14 / 2, dy: 0)
        
        let knobX: CGFloat
        if maxValue - minValue == 0 {
            knobX = innerRect.minX
        } else {
            knobX = innerRect.minX + CGFloat((doubleValue - minValue) / maxValue) * innerRect.width
        }

        let shadowPath = NSBezierPath(roundedRect: NSRect(x: (knobX - bounds.height / 4), y: 0, width: 10, height: bounds.height).insetBy(dx: 0.5, dy: 3.5), xRadius: 5, yRadius: 5)
        NSColor(white: 0.3, alpha: 0.3).setFill()
        shadowPath.fill()

        let knobPath = NSBezierPath(roundedRect: NSRect(x: (knobX - bounds.height / 4), y: 0, width: 10, height: bounds.height).insetBy(dx: 1, dy: 4), xRadius: 5, yRadius: 5)

        let amount = CGFloat(floatValue / Float(maxValue))
        let knobColor = barGradient.interpolatedColor(atLocation: amount)
        knobColor.setFill()
        knobPath.fill()
    }
}
