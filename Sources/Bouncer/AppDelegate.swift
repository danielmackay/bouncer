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
        // Runs for every quit that goes through terminate: the menu's Quit, ⌘Q, logout
        // and shutdown. A force quit or SIGKILL skips it, but then Bouncer's status items
        // vanish with the process, taking the Divider's width with them.
        menuBar?.prepareForQuit()
    }
}
