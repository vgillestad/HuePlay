//
//  ColorWheel.swift
//  SwiftHSVColorPicker
//
//  Created by johankasperi on 2015-08-20.
//
import UIKit

protocol ColorWheelDelegate: class {
    func hueAndSaturationSelected(_ hue: CGFloat, saturation: CGFloat)
}

class ColorWheel: UIView {
    var color: UIColor!

    // Layer for the Hue and Saturation wheel
    var wheelLayer: CALayer!
    
    // Overlay layer for the brightness
    var brightnessLayer: CAShapeLayer!
    var brightness: CGFloat = 1.0
    
    // Layer for the indicator
    var indicatorLayer: CAShapeLayer!
    var point: CGPoint!
    var indicatorCircleRadius: CGFloat = 12.0
    var indicatorColor: CGColor = UIColor.lightGray.cgColor
    var indicatorBorderWidth: CGFloat = 2.0
    
    // Retina scaling factor
    let scale: CGFloat = UIScreen.main.scale
    
    weak var delegate: ColorWheelDelegate?
  
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
    }
    
    init(frame: CGRect, color: UIColor!) {
        super.init(frame: frame)
        
        self.color = color
        
        // Layer for the Hue/Saturation wheel
        wheelLayer = CALayer()
        wheelLayer.frame = CGRect(x: 20, y: 20, width: self.frame.width-40, height: self.frame.height-40)
        wheelLayer.contents = createColorWheel(wheelLayer.frame.size)
        self.layer.addSublayer(wheelLayer)
        
        // Layer for the brightness
        brightnessLayer = CAShapeLayer()
        brightnessLayer.path = UIBezierPath(roundedRect: CGRect(x: 20.5, y: 20.5, width: self.frame.width-40.5, height: self.frame.height-40.5), cornerRadius: (self.frame.height-40.5)/2).cgPath
        self.layer.addSublayer(brightnessLayer)
        
        // Layer for the indicator
        indicatorLayer = CAShapeLayer()
        indicatorLayer.strokeColor = indicatorColor
        indicatorLayer.lineWidth = indicatorBorderWidth
        indicatorLayer.fillColor = nil
        self.layer.addSublayer(indicatorLayer)
        
        setViewColor(color);
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        indicatorCircleRadius = 18.0
        touchHandler(touches)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchHandler(touches)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        indicatorCircleRadius = 12.0
        touchHandler(touches)
    }
    
    func touchHandler(_ touches: Set<UITouch>) {
        // Set reference to the location of the touch in member point
        if let touch = touches.first {
            point = touch.location(in: self)
        }
        
        let indicator = getIndicatorCoordinate(point)
        point = indicator.point
        var color = (hue: CGFloat(0), saturation: CGFloat(0))
        if !indicator.isCenter  {
            color = hueSaturationAtPoint(CGPoint(x: point.x*scale, y: point.y*scale))
        }
        
        self.color = UIColor(hue: color.hue, saturation: color.saturation, brightness: self.brightness, alpha: 1.0)
        
        // Notify delegate of the new Hue and Saturation
        delegate?.hueAndSaturationSelected(color.hue, saturation: color.saturation)
        
        // Draw the indicator
        drawIndicator()
    }
    
    func drawIndicator() {
        // Draw the indicator
        if (point != nil) {
            indicatorLayer.path = UIBezierPath(roundedRect: CGRect(x: point.x-indicatorCircleRadius, y: point.y-indicatorCircleRadius, width: indicatorCircleRadius*2, height: indicatorCircleRadius*2), cornerRadius: indicatorCircleRadius).cgPath

            indicatorLayer.fillColor = self.color.cgColor
        }
    }
    
    func getIndicatorCoordinate(_ coord: CGPoint) -> (point: CGPoint, isCenter: Bool) {
        // Making sure that the indicator can't get outside the Hue and Saturation wheel
        
        let dimension: CGFloat = min(wheelLayer.frame.width, wheelLayer.frame.height)
        let radius: CGFloat = dimension/2
        let wheelLayerCenter: CGPoint = CGPoint(x: wheelLayer.frame.origin.x + radius, y: wheelLayer.frame.origin.y + radius)

        let dx: CGFloat = coord.x - wheelLayerCenter.x
        let dy: CGFloat = coord.y - wheelLayerCenter.y
        let distance: CGFloat = sqrt(dx*dx + dy*dy)
        var outputCoord: CGPoint = coord
        
        // If the touch coordinate is outside the radius of the wheel, transform it to the edge of the wheel with polar coordinates
        if (distance > radius) {
            let theta: CGFloat = atan2(dy, dx)
            outputCoord.x = radius * cos(theta) + wheelLayerCenter.x
            outputCoord.y = radius * sin(theta) + wheelLayerCenter.y
        }
        
        // If the touch coordinate is close to center, focus it to the very center at set the color to white
        let whiteThreshold: CGFloat = 10
        var isCenter = false
        if (distance < whiteThreshold) {
            outputCoord.x = wheelLayerCenter.x
            outputCoord.y = wheelLayerCenter.y
            isCenter = true
        }
        return (outputCoord, isCenter)
    }
    
    func createColorWheel(_ size: CGSize) -> CGImage {
        // Creates a bitmap of the Hue Saturation wheel
        let originalWidth: CGFloat = size.width
        let originalHeight: CGFloat = size.height
        let dimension: CGFloat = min(originalWidth*scale, originalHeight*scale)
        let bufferLength: Int = Int(dimension * dimension * 4)
        
        let bitmapData: CFMutableData = CFDataCreateMutable(nil, 0)
        CFDataSetLength(bitmapData, CFIndex(bufferLength))
        let bitmap = CFDataGetMutableBytePtr(bitmapData)
        
        for y in stride(from: CGFloat(0), to: dimension, by: CGFloat(1)) {
            for x in stride(from: CGFloat(0), to: dimension, by: CGFloat(1)) {
                var hsv: HSV = (hue: 0, saturation: 0, brightness: 0, alpha: 0)
                var rgb: RGB = (red: 0, green: 0, blue: 0, alpha: 0)
                
                let color = hueSaturationAtPoint(CGPoint(x: x, y: y))
                let hue = color.hue
                let saturation = color.saturation
                var a: CGFloat = 0.0
                if (saturation < 1.0) {
                    // Antialias the edge of the circle.
                    if (saturation > 0.99) {
                        a = (1.0 - saturation) * 100
                    } else {
                        a = 1.0;
                    }
                    
                    hsv.hue = hue
                    hsv.saturation = saturation
                    hsv.brightness = 1.0
                    hsv.alpha = a
                    rgb = hsv2rgb(hsv)
                }
                let offset = Int(4 * (x + y * dimension))
                bitmap?[offset] = UInt8(rgb.red*255)
                bitmap?[offset + 1] = UInt8(rgb.green*255)
                bitmap?[offset + 2] = UInt8(rgb.blue*255)
                bitmap?[offset + 3] = UInt8(rgb.alpha*255)
            }
        }
        
        // Convert the bitmap to a CGImage
        let colorSpace: CGColorSpace? = CGColorSpaceCreateDeviceRGB()
        let dataProvider: CGDataProvider? = CGDataProvider(data: bitmapData)
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo().rawValue | CGImageAlphaInfo.last.rawValue)
        let imageRef: CGImage? = CGImage(width: Int(dimension), height: Int(dimension), bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: Int(dimension) * 4, space: colorSpace!, bitmapInfo: bitmapInfo, provider: dataProvider!, decode: nil, shouldInterpolate: false, intent: CGColorRenderingIntent.defaultIntent)
        return imageRef!
    }
    
    func hueSaturationAtPoint(_ position: CGPoint) -> (hue: CGFloat, saturation: CGFloat) {
        // Get hue and saturation for a given point (x,y) in the wheel
        
        let c = wheelLayer.frame.width * scale / 2
        let dx = CGFloat(position.x - c) / c
        let dy = CGFloat(position.y - c) / c
        let d = sqrt(CGFloat (dx * dx + dy * dy))
        
        let saturation: CGFloat = d
        
        var hue: CGFloat
        if (d == 0) {
            hue = 0;
        } else {
            hue = acos(dx/d) / CGFloat(Double.pi) / 2.0
            if (dy < 0) {
                hue = 1.0 - hue
            }
        }
        return (hue, saturation)
    }
    
    func pointAtHueSaturation(_ hue: CGFloat, saturation: CGFloat) -> CGPoint {
        // Get a point (x,y) in the wheel for a given hue and saturation
        
        let dimension: CGFloat = min(wheelLayer.frame.width, wheelLayer.frame.height)
        let radius: CGFloat = saturation * dimension / 2
        let x = dimension / 2 + radius * cos(hue * CGFloat(Double.pi) * 2) + 20;
        let y = dimension / 2 + radius * sin(hue * CGFloat(Double.pi) * 2) + 20;
        return CGPoint(x: x, y: y)
    }
    
    func setViewColor(_ color: UIColor!) {
        // Update the entire view with a given color
        
        var hue: CGFloat = 0.0, saturation: CGFloat = 0.0, brightness: CGFloat = 0.0, alpha: CGFloat = 0.0
        let ok: Bool = color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        if (!ok) {
            print("SwiftHSVColorPicker: exception <The color provided to SwiftHSVColorPicker is not convertible to HSV>")
        }
        self.color = color
        self.brightness = brightness
        brightnessLayer.fillColor = UIColor(white: 0, alpha: 1.0-self.brightness).cgColor
        point = pointAtHueSaturation(hue, saturation: saturation)
        drawIndicator()
    }
    
    func setViewBrightness(_ _brightness: CGFloat) {
        // Update the brightness of the view
        
        var hue: CGFloat = 0.0, saturation: CGFloat = 0.0, brightness: CGFloat = 0.0, alpha: CGFloat = 0.0
        let ok: Bool = color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        if (!ok) {
            print("SwiftHSVColorPicker: exception <The color provided to SwiftHSVColorPicker is not convertible to HSV>")
        }
        self.brightness = _brightness
        brightnessLayer.fillColor = UIColor(white: 0, alpha: 1.0-self.brightness).cgColor
        self.color = UIColor(hue: hue, saturation: saturation, brightness: _brightness, alpha: 1.0)
        drawIndicator()
    }
}

//
//  ColorUtils.swift
//  SwiftHSVColorPicker
//
//  Created by johankasperi on 2015-08-20.
//
import UIKit

// Typealias for RGB color values
typealias RGB = (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)

// Typealias for HSV color values
typealias HSV = (hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat)

func hsv2rgb(_ hsv: HSV) -> RGB {
    // Converts HSV to a RGB color
    var rgb: RGB = (red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
    var r: CGFloat
    var g: CGFloat
    var b: CGFloat
    
    let i = Int(hsv.hue * 6)
    let f = hsv.hue * 6 - CGFloat(i)
    let p = hsv.brightness * (1 - hsv.saturation)
    let q = hsv.brightness * (1 - f * hsv.saturation)
    let t = hsv.brightness * (1 - (1 - f) * hsv.saturation)
    switch (i % 6) {
        case 0: r = hsv.brightness; g = t; b = p; break;
        
        case 1: r = q; g = hsv.brightness; b = p; break;
        
        case 2: r = p; g = hsv.brightness; b = t; break;
        
        case 3: r = p; g = q; b = hsv.brightness; break;
        
        case 4: r = t; g = p; b = hsv.brightness; break;
        
        case 5: r = hsv.brightness; g = p; b = q; break;
        
        default: r = hsv.brightness; g = t; b = p;
    }
    
    rgb.red = r
    rgb.green = g
    rgb.blue = b
    rgb.alpha = hsv.alpha
    return rgb
}

func rgb2hsv(_ rgb: RGB) -> HSV {
    // Converts RGB to a HSV color
    var hsb: HSV = (hue: 0.0, saturation: 0.0, brightness: 0.0, alpha: 0.0)
    
    let rd: CGFloat = rgb.red
    let gd: CGFloat = rgb.green
    let bd: CGFloat = rgb.blue

    let maxV: CGFloat = max(rd, max(gd, bd))
    let minV: CGFloat = min(rd, min(gd, bd))
    var h: CGFloat = 0
    var s: CGFloat = 0
    let b: CGFloat = maxV
    
    let d: CGFloat = maxV - minV
    
    s = maxV == 0 ? 0 : d / minV;
    
    if (maxV == minV) {
        h = 0
    } else {
        if (maxV == rd) {
            h = (gd - bd) / d + (gd < bd ? 6 : 0)
        } else if (maxV == gd) {
            h = (bd - rd) / d + 2
        } else if (maxV == bd) {
            h = (rd - gd) / d + 4
        }
        
        h /= 6;
    }
    
    hsb.hue = h
    hsb.saturation = s
    hsb.brightness = b
    hsb.alpha = rgb.alpha
    return hsb
}
