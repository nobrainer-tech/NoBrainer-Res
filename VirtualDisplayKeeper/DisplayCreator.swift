import AppKit
import CoreGraphics
import Foundation
import ObjectiveC

struct VDConfig: Codable {
    var name: String
    var width: Int
    var height: Int
    var refreshRate: Double
    var hiDPI: Bool
    var connectOnStartup: Bool
}

func createVirtualDisplay(config: VDConfig) -> AnyObject? {
    dlopen("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics", RTLD_LAZY)

    guard
        let DescriptorClass = NSClassFromString("CGVirtualDisplayDescriptor") as? NSObject.Type,
        let DisplayClass    = NSClassFromString("CGVirtualDisplay") as? NSObject.Type,
        let ModeClass       = NSClassFromString("CGVirtualDisplayMode") as? NSObject.Type,
        let SettingsClass   = NSClassFromString("CGVirtualDisplaySettings") as? NSObject.Type
    else {
        fputs("[VDKeeper] CGVirtualDisplay classes not available\n", stderr)
        return nil
    }

    let descriptor = DescriptorClass.init()
    descriptor.setValue(config.name,   forKey: "name")
    descriptor.setValue(config.width,  forKey: "maxPixelsWide")
    descriptor.setValue(config.height, forKey: "maxPixelsHigh")
    descriptor.setValue(0x05AC,        forKey: "vendorID")
    descriptor.setValue(0x1234,        forKey: "productID")
    descriptor.setValue(1,             forKey: "serialNum")
    descriptor.setValue(DispatchQueue.main, forKey: "queue")
    descriptor.setValue(NSValue(size: CGSize(width: 597, height: 374)),
                        forKey: "sizeInMillimeters")

    guard
        let allocResult = (DisplayClass as AnyObject).perform(Selector("alloc")),
        let display = allocResult.takeUnretainedValue()
                        .perform(Selector(("initWithDescriptor:")), with: descriptor)?
                        .takeRetainedValue()
    else {
        fputs("[VDKeeper] Failed to init CGVirtualDisplay\n", stderr)
        return nil
    }

    typealias InitModeFn = @convention(c) (AnyObject, Selector, UInt32, UInt32, Double) -> AnyObject
    let msgSendFn = unsafeBitCast(
        dlsym(dlopen(nil, RTLD_LAZY), "objc_msgSend"),
        to: InitModeFn.self
    )
    let initModeSel = Selector(("initWithWidth:height:refreshRate:"))

    var modes: [AnyObject] = []
    if let a = (ModeClass as AnyObject).perform(Selector("alloc"))?.takeUnretainedValue() {
        modes.append(msgSendFn(a, initModeSel, UInt32(config.width), UInt32(config.height), config.refreshRate))
    }
    if config.hiDPI,
       let a2 = (ModeClass as AnyObject).perform(Selector("alloc"))?.takeUnretainedValue() {
        modes.append(msgSendFn(a2, initModeSel, UInt32(config.width * 2), UInt32(config.height * 2), config.refreshRate))
    }

    let settings = SettingsClass.init()
    settings.setValue(modes,        forKey: "modes")
    settings.setValue(config.hiDPI, forKey: "hiDPI")
    (display as AnyObject).perform(Selector(("applySettings:")), with: settings)

    return display
}
