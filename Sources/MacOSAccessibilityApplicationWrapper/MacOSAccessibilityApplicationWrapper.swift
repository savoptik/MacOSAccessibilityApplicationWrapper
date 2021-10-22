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

    private static func getString(FromPTR ptr: UnsafeMutablePointer<CFTypeRef?>) -> String? {
        if let r: UnsafePointer<CFString> = ptr as? UnsafePointer<CFString>, let s: NSString = r as? NSString {
            return s as String
        }

        return nil
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
        if let chl = MacOSAccessibilityElementWrapper.getAx(Attribute: kAXChildrenAttribute, andAxElement: axElementRef) {
            let childrenList: CFArray = chl as! CFArray
            let count = CFArrayGetCount(childrenList)
            var children: [MacOSAccessibilityElementWrapper] = []
            for item in 0..<count {
                let child: AXUIElement = CFArrayGetValueAtIndex(childrenList, item) as! AXUIElement
                children.append(MacOSAccessibilityElementWrapper(WithAXElement: child))
            }

            return children
        }

        return nil
    }

    func accessibilityLabel() -> String {
        if let label = MacOSAccessibilityElementWrapper.getAx(Attribute: kAXLabelValueAttribute, andAxElement: axElementRef),
        let s = MacOSAccessibilityElementWrapper.getString(FromPTR: label) {
            return s
        }

        return "none"
    }

    func accessibilityRole() -> NSAccessibility.Role? {
        if let role = MacOSAccessibilityElementWrapper.getAx(Attribute: kAXRoleAttribute, andAxElement: axElementRef),
        let s = MacOSAccessibilityElementWrapper.getString(FromPTR: role) {
            return NSAccessibility.Role.init(rawValue: s)
        }

        return nil
    }
}
