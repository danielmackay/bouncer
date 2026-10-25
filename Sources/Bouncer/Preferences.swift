import BouncerCore
import Foundation
import Observation

/// Bouncer's user defaults. Every change is written straight away; there is no Save step.
@MainActor
@Observable
final class Preferences {
    private enum Key {
        static let autoCollapseTimeoutSeconds = "autoCollapseTimeoutSeconds"
    }

    @ObservationIgnored private let defaults: UserDefaults
    /// Called after every change to the timeout, so the core can use it for the next countdown.
    @ObservationIgnored var onAutoCollapseTimeoutChange: ((AutoCollapseTimeout) -> Void)?

    var autoCollapseTimeout: AutoCollapseTimeout {
        didSet {
            defaults.set(autoCollapseTimeout.storedSeconds, forKey: Key.autoCollapseTimeoutSeconds)
            onAutoCollapseTimeoutChange?(autoCollapseTimeout)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // `integer(forKey:)` can't tell "never set" from 0, and 0 means Off.
        let stored = defaults.object(forKey: Key.autoCollapseTimeoutSeconds) as? Int
        autoCollapseTimeout = AutoCollapseTimeout(storedSeconds: stored)
    }
}
