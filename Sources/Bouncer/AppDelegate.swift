import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBar: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBar = MenuBarController()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Covers every way out (the menu's Quit, logout, a kill from Activity Monitor
        // that goes through terminate) so no Menu Bar Item is left in the System Overflow.
        menuBar?.resetDivider()
    }
}
