//
//  RGBtoHSV.swift
//  XcoatOfPaint
//
//  Created by Christian Lobach on 25.04.21.
//

import Cocoa
// swiftlint:disable identifier_name large_tuple
// https://github.com/trav-ma/TMReplaceColorHue/blob/master/TMReplaceColorHue/ViewController.swift

func HSVtoRGB(_ h: Float, s: Float, v: Float) -> (r: Float, g: Float, b: Float) {
    var r: Float = 0
    var g: Float = 0
    var b: Float = 0
    let C = s * v
    let HS = h * 6.0
    let X = C * (1.0 - fabsf(fmodf(HS, 2.0) - 1.0))
    if HS >= 0 && HS < 1 {
        r = C
        g = X
        b = 0
    } else if HS >= 1 && HS < 2 {
        r = X
        g = C
        b = 0
    } else if HS >= 2 && HS < 3 {
        r = 0
        g = C
        b = X
    } else if HS >= 3 && HS < 4 {
        r = 0
        g = X
        b = C
    } else if HS >= 4 && HS < 5 {
        r = X
        g = 0
        b = C
    } else if HS >= 5 && HS < 6 {
        r = C
        g = 0
        b = X
    }
    let m = v - C
    r += m
    g += m
    b += m
    return (r, g, b)
}

func RGBtoHSV(_ r: Float, g: Float, b: Float) -> (h: Float, s: Float, v: Float) {
    var h: CGFloat = 0
    var s: CGFloat = 0
    var v: CGFloat = 0
    let col = NSColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1.0)
    col.getHue(&h, saturation: &s, brightness: &v, alpha: nil)
    return (Float(h), Float(s), Float(v))
}
