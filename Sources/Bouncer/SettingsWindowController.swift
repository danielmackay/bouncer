import AppKit
import SwiftUI
import os

/// Hosts the SwiftUI Settings view in a plain window. An agent app has no app menu, so
/// SwiftUI's `Settings` scene and its ⌘, shortcut aren't available; the Toggle's menu
/// opens this instead.
@MainActor
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    private static let log = Logger(subsystem: "dev.danielmackay.Bouncer", category: "Settings")
    private let launchAtLogin: LaunchAtLogin

    init(preferences: Preferences, launchAtLogin: LaunchAtLogin) {
        self.launchAtLogin = launchAtLogin
        let hosting = NSHostingController(rootView: SettingsView(preferences: preferences, launchAtLogin: launchAtLogin))
        hosting.sizingOptions = .preferredContentSize
        let window = NSWindow(contentViewController: hosting)
        window.title = "Bouncer Settings"
        window.styleMask = [.titled, .closable]
        // Closing only hides it; the next Settings… shows the same window.
        window.isReleasedWhenClosed = false
        super.init(window: window)
        window.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("SettingsWindowController is created in code only")
    }

    /// Brings the window to the front. Bouncer is never the active app while its menu is
    /// used from the menu bar, so it has to activate itself or the window opens behind others.
    func show() {
        guard let window else {
            Self.log.error("The Settings window controller has no window to show")
            NSSound.beep()
            return
        }
        if !window.isVisible {
            window.center()
        }
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    /// Catches launch at login being changed in System Settings while the window was
    /// in the background.
    func windowDidBecomeKey(_ notification: Notification) {
        launchAtLogin.refresh()
    }
}
