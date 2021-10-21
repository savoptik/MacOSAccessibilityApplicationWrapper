import Foundation
import AppKit

public class MacOSAccessibilityElementWrapper : NSObject, NSAccessibilityElementProtocol {
    let axElementRef: AXUIElement
    let windows: [MacOSAccessibilityElementWrapper]?

    public init(WithPID pid: Int32) throws {
        let ax = AXUIElementCreateApplication(pid)
        if let wl = MacOSAccessibilityElementWrapper.getAx(Attribute: kAXWindowsAttribute, andAxElement: ax) {
            let windowList: CFArray = wl as! CFArray
            let count = CFArrayGetCount(windowList)
            var w: [MacOSAccessibilityElementWrapper] = []
            for item in 0..<count {
                let axWindow: AXUIElement = CFArrayGetValueAtIndex(windowList, item) as! AXUIElement
                w.append(MacOSAccessibilityElementWrapper(WithAXElement: axWindow))
            }
            windows = w
            if w.isEmpty {
                throw MAAWErrors.appDoesNotHaveWindows
            }
            axElementRef = CFArrayGetValueAtIndex(windowList, 0) as! AXUIElement
        }
        throw MAAWErrors.falePIDInitialise
    }

    public init(WithAXElement ax: AXUIElement) {
        axElementRef = ax
        windows = nil
    }

    subscript(index: Int) -> MacOSAccessibilityElementWrapper? {
        get {
            if let w = windows {
                return index >= 0 && index < w.count ? w[index] : nil
            }
            if let c = self.accessibilityChildren(),
               let children = c as? [MacOSAccessibilityElementWrapper] {
                return index >= 0 && index < children.count ? children[index] : nil
            }
            return nil
        }
    }

    private static func getAx(Attribute attribute: String, andAxElement ax: AXUIElement) -> UnsafeMutablePointer<CFTypeRef?>? {
        var ret = UnsafeMutablePointer<CFTypeRef?>.allocate(capacity: 0)
        AXUIElementCopyAttributeValue(ax, attribute as CFString, ret)
        return ret
    }

    // NSAccessibilityElement protocole methods

    public func accessibilityFrame() -> NSRect {
        return NSRect.zero
    }

    public func accessibilityParent() -> Any? {
        if let parent = MacOSAccessibilityElementWrapper.getAx(Attribute: kAXParentAttribute, andAxElement: axElementRef) {
            return MacOSAccessibilityElementWrapper(WithAXElement: parent as! AXUIElement)
        }

        return nil
    }

    func accessibilityChildren() -> [Any]? {
        return nil
    }
}
