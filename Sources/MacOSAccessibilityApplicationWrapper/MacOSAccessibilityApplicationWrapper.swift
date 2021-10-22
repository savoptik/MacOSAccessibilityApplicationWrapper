import Foundation
import AppKit

public class MacOSAccessibilityElementWrapper : NSObject, NSAccessibilityElementProtocol {

    let axElementRef: AXUIElement
    let windows: [MacOSAccessibilityElementWrapper]?

    public init(WithPID pid: Int32) throws {
        print("test 1")
        let ax = AXUIElementCreateApplication(pid)
        print("test 2")
        if let wl = MacOSAccessibilityElementWrapper.getAx(Attribute: kAXWindowsAttribute, andAxElement: ax) {
            print("test 3,")
            let windowList = wl as! CFArray
            print("test 4")
            let count = CFArrayGetCount(windowList)
            print("test 5")
            var w: [MacOSAccessibilityElementWrapper] = []
            for item in 0..<count {
                print("test 5.1 \(count)")
                let axWindowRef = CFArrayGetValueAtIndex(windowList, item)
                print("test 5.2")
let axWindow = axWindowRef as! AXUIElement
                print("test 5.3")
                w.append(MacOSAccessibilityElementWrapper(WithAXElement: axWindow))
            }
            print("test 6")
            windows = w
            if w.isEmpty {
                throw MAAWErrors.appDoesNotHaveWindows
            }
            print("test 7")
            axElementRef = CFArrayGetValueAtIndex(
                    windowList as! CFArray, 0) as! AXUIElement
            print("test 8")
        }
        throw MAAWErrors.falePIDInitialise
    }

    public init(WithAXElement ax: AXUIElement) {
        axElementRef = ax
        windows = nil
    }

    public subscript(index: Int) -> MacOSAccessibilityElementWrapper? {
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

    private static func getAx(Attribute attribute: String, andAxElement ax: AXUIElement) -> AnyObject? {
        var ret: AnyObject?

        let err = AXUIElementCopyAttributeValue(ax, attribute as CFString, &ret)

        if err.rawValue == 0 {
            return ret
        }

        return nil
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

    public func accessibilityChildren() -> [Any]? {
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

    public func accessibilityLabel() -> String {
        if let label = MacOSAccessibilityElementWrapper.getAx(Attribute: kAXLabelValueAttribute, andAxElement: axElementRef),
        let s = label as? String {
            return s
        }

        return "none"
    }

    public func accessibilityRole() -> NSAccessibility.Role? {
        if let role = MacOSAccessibilityElementWrapper.getAx(Attribute: kAXRoleAttribute, andAxElement: axElementRef),
        let s = role as? String {
            return NSAccessibility.Role.init(rawValue: s)
        }

        return nil
    }
}
