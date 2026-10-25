import BouncerCore

extension Bouncer {
    /// A Bouncer that has seen its displays and finished launching, the way the app
    /// drives it at startup. Scenarios start from here unless launch itself is under test.
    static func launched(displayWidths: [Double]) -> Bouncer {
        var bouncer = Bouncer()
        bouncer.handle(.displayWidthsChanged(displayWidths))
        bouncer.handle(.launchFinished)
        return bouncer
    }
}
