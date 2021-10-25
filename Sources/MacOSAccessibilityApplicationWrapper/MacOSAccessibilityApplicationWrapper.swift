import Foundation
import AppKit

public class MacOSAccessibilityElementWrapper : NSAccessibilityElement {

    let axElementRef: AXUIElement
    let windows: [MacOSAccessibilityElementWrapper]?

    public init(WithPID pid: Int32) throws {
        let ax = AXUIElementCreateApplication(pid)
        if let wl = MacOSAccessibilityElementWrapper.getAx(Attribute: kAXWindowsAttribute, andAxElement: ax) {
            let windowList = wl as! [AXUIElement]
            var w: [MacOSAccessibilityElementWrapper] = []
            for item in windowList {
                w.append(MacOSAccessibilityElementWrapper(WithAXElement: item))
            }
            windows = w
            if w.isEmpty {
                throw MAAWErrors.appDoesNotHaveWindows
            }
            axElementRef = windowList[0]
            return
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

    private static func getAxValuePoint(axValue: AXValue) -> NSPoint {
        var ret = NSPoint.zero
        if AXValueGetValue(axValue, .cgPoint, &ret) {
            return ret
        }

        return NSPoint.zero
    }

    private static func getAxValueSize(axValue: AXValue) -> NSSize {
        var ret = NSSize.zero
        if AXValueGetValue(axValue, .cgSize, &ret) {
            return ret
        }

        return NSSize.zero
    }

    // NSAccessibilityElement protocole methods

    public override func accessibilityFrame() -> NSRect {
        // get location
        if let loc = MacOSAccessibilityElementWrapper.getAx(Attribute: kAXPositionAttribute, andAxElement: axElementRef) {
            let av = loc as! AXValue
            let point = MacOSAccessibilityElementWrapper.getAxValuePoint(axValue: av)
            if let s = MacOSAccessibilityElementWrapper.getAx(Attribute: kAXSizeAttribute, andAxElement: axElementRef) {
                let sav = s as! AXValue
                let size = MacOSAccessibilityElementWrapper.getAxValueSize(axValue: sav)
                return NSRect.init(origin: point, size: size)
            }
        }

        return NSRect.zero
    }

    public override func accessibilityParent() -> Any? {
        if let parent = MacOSAccessibilityElementWrapper.getAx(Attribute: kAXParentAttribute, andAxElement: axElementRef) {
            return MacOSAccessibilityElementWrapper(WithAXElement: parent as! AXUIElement)
        }

        return nil
    }

    public override func accessibilityChildren() -> [Any]? {
        if let chl = MacOSAccessibilityElementWrapper.getAx(Attribute: kAXChildrenAttribute, andAxElement: axElementRef) {
            if let childrenList = chl as? [AXUIElement] {
                var children: [MacOSAccessibilityElementWrapper] = []
                for item in childrenList {
                    children.append(MacOSAccessibilityElementWrapper(WithAXElement: item))
                }

                return children
            }
            }

        return nil
    }

    public override func accessibilityLabel() -> String {
        if let label = MacOSAccessibilityElementWrapper.getAx(Attribute: kAXDescription, andAxElement: axElementRef),
        let s = label as? String {
            return s
        }

        return "none"
    }

    public override func accessibilityRole() -> NSAccessibility.Role? {
        if let role = MacOSAccessibilityElementWrapper.getAx(Attribute: kAXRoleAttribute, andAxElement: axElementRef),
        let s = role as? String {
            return NSAccessibility.Role.init(rawValue: s)
        }

        return nil
    }

}
