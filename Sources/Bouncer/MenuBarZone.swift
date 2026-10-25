import AppKit

/// The menu bar plus a band below it, where a Menu Bar Item's menu opens. While the
/// pointer is in here, Auto-collapse waits.
@MainActor
enum MenuBarZone {
    /// Deep enough to cover a typical Menu Bar Item menu's top rows, where the pointer
    /// sits while choosing from it.
    static let depthBelowMenuBar: CGFloat = 300

    /// Whether the pointer is in the zone of whichever display it is on. Reads the global
    /// pointer location, which needs no permission.
    static func containsPointer() -> Bool {
        let pointer = NSEvent.mouseLocation
        // The pointer can sit exactly on a screen's top or right edge, which
        // `NSRect.contains` excludes, so match with NSMouseInRect's inclusive edges.
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(pointer, $0.frame, false) }) else {
            return false
        }
        let zoneBottom = screen.frame.maxY - menuBarHeight(on: screen) - depthBelowMenuBar
        return pointer.y >= zoneBottom
    }

    private static func menuBarHeight(on screen: NSScreen) -> CGFloat {
        // visibleFrame excludes the menu bar, and on a notched display the taller one.
        // With the menu bar set to hide automatically it excludes nothing, so fall back
        // to the standard thickness.
        let reserved = screen.frame.maxY - screen.visibleFrame.maxY
        return max(reserved, NSStatusBar.system.thickness)
    }
}
