import CoreGraphics
import IOKit
import IOKit.graphics

struct Display: Identifiable, Hashable {
    let id: CGDirectDisplayID
    let name: String
    let isBuiltIn: Bool
    let isMain: Bool
    var modes: [DisplayMode]
    var currentMode: DisplayMode?

    var sortedModes: [DisplayMode] {
        modes.sorted { lhs, rhs in
            if lhs.width != rhs.width { return lhs.width > rhs.width }
            if lhs.height != rhs.height { return lhs.height > rhs.height }
            if lhs.isHiDPI != rhs.isHiDPI { return lhs.isHiDPI }
            return lhs.refreshRate > rhs.refreshRate
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Display, rhs: Display) -> Bool {
        lhs.id == rhs.id
    }
}

extension Display {
    static func displayName(for displayID: CGDirectDisplayID) -> String {
        if let name = ioKitDisplayName(for: displayID) {
            return name
        }

        if CGDisplayIsBuiltin(displayID) != 0 {
            return "Built-in Display"
        }
        return "Display \(displayID)"
    }

    private static func ioKitDisplayName(for displayID: CGDirectDisplayID) -> String? {
        var iterator: io_iterator_t = 0
        let matching = IOServiceMatching("IODisplayConnect")
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return nil
        }
        defer { IOObjectRelease(iterator) }

        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer {
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }

            guard let info = IODisplayCreateInfoDictionary(service, IOOptionBits(kIODisplayOnlyPreferredName)).takeRetainedValue() as? [String: Any] else {
                continue
            }

            guard let vendorID = info[kDisplayVendorID] as? UInt32,
                  let productID = info[kDisplayProductID] as? UInt32 else {
                continue
            }

            // Match by vendor and product ID
            if vendorID == CGDisplayVendorNumber(displayID) &&
               productID == CGDisplayModelNumber(displayID) {
                if let names = info[kDisplayProductName] as? [String: String],
                   let name = names["en_US"] ?? names.values.first {
                    return name
                }
            }
        }

        return nil
    }
}
