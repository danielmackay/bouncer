import Foundation
import Observation
import ServiceManagement
import os

/// Launch at login through the main-app login item service. The state shown is always the
/// system's live registration status, never a stored flag, because Daniel can change it
/// in System Settings → General → Login Items while Bouncer runs.
@MainActor
@Observable
final class LaunchAtLogin {
    private static let log = Logger(bouncerCategory: "LaunchAtLogin")
    /// Remembers only that the on-by-default registration has been done once, so turning
    /// launch at login off isn't undone on the next launch. It is not the switch's state.
    private static let defaultAppliedKey = "launchAtLoginDefaultApplied"

    @ObservationIgnored private let service = SMAppService.mainApp
    @ObservationIgnored private let defaults: UserDefaults

    private(set) var status: SMAppService.Status
    /// The last registration failure, shown in the Settings window until the next attempt.
    private(set) var errorMessage: String?

    /// On only once Bouncer will really launch at login. While approval is pending it
    /// won't, so the switch shows off and the approval hint explains what's missing.
    var isEnabled: Bool { status == .enabled }
    var needsApproval: Bool { status == .requiresApproval }
    /// Bouncer has asked to launch at login, whether or not it's approved yet. Asking
    /// again wouldn't get it approved any sooner.
    private var isRegistered: Bool { isEnabled || needsApproval }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        status = service.status
    }

    /// Re-reads the live status, for when the Settings window comes to the front.
    func refresh() {
        status = service.status
    }

    /// Launch at login is on by default, so the first launch registers it.
    func applyDefaultOnFirstLaunch() {
        guard !defaults.bool(forKey: Self.defaultAppliedKey) else { return }
        refresh()
        if !isRegistered {
            setEnabled(true)
        }
        // A failed first registration leaves the marker unset so the next launch retries.
        if isRegistered {
            defaults.set(true, forKey: Self.defaultAppliedKey)
        }
    }

    func setEnabled(_ enabled: Bool) {
        errorMessage = nil
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
            Self.log.info("Launch at login \(enabled ? "registered" : "unregistered", privacy: .public)")
        } catch {
            let action = enabled ? "turn on" : "turn off"
            errorMessage = "Couldn't \(action) launch at login: \(error.localizedDescription)"
            Self.log.error("Launch at login \(action, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
        }
        // Whatever happened, show what the system now says rather than what was asked for.
        refresh()
        Self.log.info("Launch at login status: \(String(describing: self.status), privacy: .public)")
    }

    func openLoginItemsSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
