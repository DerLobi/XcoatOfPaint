//
//  ImageEditor.swift
//  XcoatOfPaint
//
//  Created by Christian Lobach on 25.04.21.
//

import Cocoa
import CoreImage.CIFilterBuiltins
import Combine

// https://github.com/trav-ma/TMReplaceColorHue/blob/master/TMReplaceColorHue/ViewController.swift
class ImageEditor: NSObject {

    var icnsURL: URL? {
        didSet {
            guard let icnsURL = icnsURL else { return }
            let data = try? Data(contentsOf: icnsURL)
            let image = data.flatMap(NSImage.init(data:))
            inputImage = image
        }
    }

    @objc var brightnessAdjustment: Float = 0
    @objc var saturationAdjustment: Float = 0
    @objc var destCenterHueAngle: Float = 0.57

    @objc dynamic private(set) var inputImage: NSImage?

    @objc dynamic var outputImage: NSImage?

    private let defaultHue: Float = 205
    private let maximumMonochromeSaturationThreshold: Float = 0.2
    private let maximumMonochromeBrightnessThreshold: Float = 0.2

    private var cancellables = Set<AnyCancellable>()
    private let renderQueue = DispatchQueue(label: "RenderQueue", qos: .userInteractive)

    override init() {

        super.init()
        Publishers.Merge4(
            publisher(for: \.inputImage).map { _ in return },
            publisher(for: \.brightnessAdjustment).map { _ in return },
            publisher(for: \.saturationAdjustment).map { _ in return },
            publisher(for: \.destCenterHueAngle).map { _ in return })
            .throttle(for: .milliseconds(10), scheduler: renderQueue, latest: true)
            .map { [weak self] _ in
                self?.render()
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.outputImage, on: self)
            .store(in: &cancellables)
    }

    func render() -> NSImage? {
        guard let inputImage = inputImage,
              let bitmapRep = inputImage.representations
                .compactMap({ $0 as? NSBitmapImageRep })
                .first,
              let ciImage = CIImage(bitmapImageRep: bitmapRep)
        else { return nil }

        let centerHueAngle: Float = defaultHue/360.0

        let hueAdjustment = centerHueAngle - destCenterHueAngle
        let size = 64
        var cubeData = [Float](repeating: 0, count: size * size * size * 4)
        var rgb: [Float] = [0, 0, 0]
        var hsv: (h : Float, s : Float, v : Float)
        var newRGB: (r : Float, g : Float, b : Float)
        var offset = 0
        for z in 0 ..< size {
            rgb[2] = Float(z) / Float(size) // blue value
            for y in 0 ..< size {
                rgb[1] = Float(y) / Float(size) // green value
                for x in 0 ..< size {
                    rgb[0] = Float(x) / Float(size) // red value
                    hsv = RGBtoHSV(rgb[0], g: rgb[1], b: rgb[2])

                    // special consigeration for monochrome elements
                    // like the hammer or the "A" glyph
                    let isConsideredMonochrome =
                        hsv.s < maximumMonochromeSaturationThreshold
                     || hsv.v < maximumMonochromeBrightnessThreshold

                    if isConsideredMonochrome {
                        if saturationAdjustment < 0 {
                            hsv.s += saturationAdjustment
                        }

                        newRGB = HSVtoRGB(hsv.h, s:hsv.s, v:hsv.v)
                    } else {
                        hsv.s += saturationAdjustment
                        hsv.v += (brightnessAdjustment * hsv.v)
                        hsv.h -= hueAdjustment
                        newRGB = HSVtoRGB(hsv.h, s:hsv.s, v:hsv.v)
                    }
                    cubeData[offset] = newRGB.r
                    cubeData[offset+1] = newRGB.g
                    cubeData[offset+2] = newRGB.b
                    cubeData[offset+3] = 1.0
                    offset += 4
                }
            }
        }
        let b = cubeData.withUnsafeBufferPointer { Data(buffer: $0) }
        let data = b as Data
        let colorCube = CIFilter.colorCube()
        colorCube.cubeDimension = Float(size)
        colorCube.cubeData = data
        colorCube.inputImage = ciImage

        let context = CIContext(options: nil)
        guard let outImage = colorCube.outputImage,
              let outputImageRef = context.createCGImage(outImage, from: outImage.extent)
            else { return nil }
        return NSImage(cgImage: outputImageRef, size: inputImage.size)
    }
    
}
