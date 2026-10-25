import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBar: MenuBarController?
    private var settingsWindow: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let menuBar = MenuBarController()
        self.menuBar = menuBar

        let preferences = Preferences()
        menuBar.autoCollapseTimeoutChanged(to: preferences.autoCollapseTimeout)
        preferences.onAutoCollapseTimeoutChange = { [weak menuBar] timeout in
            menuBar?.autoCollapseTimeoutChanged(to: timeout)
        }

        let launchAtLogin = LaunchAtLogin()
        launchAtLogin.applyDefaultOnFirstLaunch()

        let settingsWindow = SettingsWindowController(preferences: preferences, launchAtLogin: launchAtLogin)
        self.settingsWindow = settingsWindow
        menuBar.onOpenSettings = { [weak settingsWindow] in settingsWindow?.show() }
        // A failed first-launch registration would otherwise go unnoticed until Daniel
        // happened to open Settings.
        if launchAtLogin.errorMessage != nil {
            settingsWindow.show()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Covers every way out (the menu's Quit, logout, a kill from Activity Monitor
        // that goes through terminate) so no Menu Bar Item is left in the System Overflow.
        menuBar?.resetDivider()
    }
}
