import os

extension Logger {
    /// Matches the bundle identifier, so one `log stream --predicate 'subsystem == …'`
    /// shows every part of Bouncer together.
    static let bouncerSubsystem = "dev.danielmackay.Bouncer"

    init(bouncerCategory category: String) {
        self.init(subsystem: Self.bouncerSubsystem, category: category)
    }
}
