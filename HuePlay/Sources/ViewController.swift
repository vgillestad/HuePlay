//
//  ViewController.swift
//  HuePlay
//
//  Created by Vegard Gillestad on 06/05/2020.
//  Copyright © 2020 Tibber. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let minBrightness:Float = 1
    let maxBrightness:Float = 254
    
    let minKelvin:Float = 2000
    let maxKelvin:Float = 6500
    let model:String = "LCT001"

    private let brightnessSlider = UISlider()
    private let brightnessLabel = UILabel()
    
    private let colorTemperatureBackground = UIView()
    private let colorTemperatureSlider = UISlider()
    private let colorTemperatureLabel = UILabel()
    
    private var xyColorWheel:ColorWheel!
    private let xyLabel = UILabel()
    private let xySelectedColor = UIView()
    
    private var currentMode:ColorMode?
    
    private var debounceTimer:Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        brightnessSlider.minimumValue = minBrightness
        brightnessSlider.maximumValue = maxBrightness
        brightnessSlider.setValue((minBrightness+maxBrightness/2), animated: false)
        brightnessSlider.addTarget(self, action: #selector(didChangeBrightness), for: .valueChanged)
        
        colorTemperatureSlider.minimumValue = minKelvin //* 0.9 //min Kelvin
        colorTemperatureSlider.maximumValue = maxKelvin //* 1.1 //max Kelvin
        colorTemperatureSlider.setValue(minKelvin, animated: false)
        colorTemperatureSlider.addTarget(self, action: #selector(didChangeColorTemperature), for: .valueChanged)
        
        brightnessLabel.frame = CGRect(x: 0, y: 50, width: view.bounds.width, height: 20)
        brightnessSlider.frame = CGRect(x: 0, y: brightnessLabel.frame.maxY, width: view.bounds.width, height: 50)
        colorTemperatureBackground.frame = CGRect(x: 0, y: brightnessSlider.frame.maxY, width: view.bounds.width, height: 100)
        colorTemperatureSlider.frame = colorTemperatureBackground.frame
        colorTemperatureLabel.frame = CGRect(x: 5, y: colorTemperatureBackground.frame.minY, width: view.bounds.width - 5, height: 50)
        
        let initialColor = HueUtilities.colorFromXY(CGPoint(x: 0.4263, y: 0.1857), forModel: model)
        xyColorWheel = ColorWheel(
            frame: CGRect(x: 0, y: colorTemperatureBackground.frame.maxY + 40, width: view.bounds.width, height: view.bounds.width),
            color: initialColor
        )
        
        xyColorWheel.delegate = self
        xySelectedColor.frame = CGRect(x: 0, y: colorTemperatureBackground.frame.maxY + 20, width: 20, height: 20)
        xyLabel.frame = CGRect(x: xySelectedColor.frame.maxX + 5, y: xySelectedColor.frame.minY, width: view.bounds.width, height: 20)
        
        view.addSubview(brightnessLabel)
        view.addSubview(brightnessSlider)
        view.addSubview(colorTemperatureBackground)
        view.addSubview(colorTemperatureLabel)
        view.addSubview(colorTemperatureSlider)
        
        view.addSubview(xyColorWheel)
        view.addSubview(xyLabel)
        view.addSubview(xySelectedColor)
        
        hueAndSaturationSelected(initialColor.hsba.hue, saturation: initialColor.hsba.saturation)
        didChangeColorTemperature()
        didChangeBrightness()
    }
    
    @objc func didChangeColorTemperature() {
        let kelvin = colorTemperatureSlider.value
        let mirek = Int(round(1000000/kelvin))
        colorTemperatureBackground.backgroundColor = UIColor(temperature: CGFloat(kelvin))
        colorTemperatureLabel.text = "ct: \(mirek) (kelvin: \(Int(kelvin)))"
        
        currentMode = .ct(mirek)
        sendToGw()
    }
    
    @objc func didChangeBrightness() {
        brightnessLabel.text = "bri: \(Int(brightnessSlider.value))"
        sendToGw()
    }
    
    private func sendToGw() {
        guard let currentMode = currentMode else { return }
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false, block: { _ in
            TibberGW.sendColor(colorMode:currentMode, brightness: Int(self.brightnessSlider.value))
        })
    }
}

extension ViewController : ColorWheelDelegate {
    func hueAndSaturationSelected(_ hue: CGFloat, saturation: CGFloat) {
        let color = UIColor(hue: hue, saturation: saturation, brightness: 1, alpha: 1)
        let point = HueUtilities.calculateXY(color, forModel: model)
        xyLabel.text = "xy: [\(point.x.fourDecimals),\(point.y.fourDecimals)]"
        xySelectedColor.backgroundColor = color
        
        currentMode = .xy([Double(point.x), Double(point.y)])
        sendToGw()
    }
}

extension CGFloat {
    var fourDecimals:CGFloat { return ((self*10000).rounded())/10000 }
}

extension UIColor {
    public var hsba: (hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat) {
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return (h, s, b, a)
    }
    
    public var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }
}
