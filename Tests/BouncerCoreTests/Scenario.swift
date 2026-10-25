import BouncerCore
import Synchronization

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

/// A clock the test moves by hand, so Auto-collapse scenarios never sleep.
final class ManualClock: BouncerClock {
    private let elapsed = Mutex<Duration>(.zero)

    var now: Duration { elapsed.withLock { $0 } }

    func advance(by duration: Duration) {
        elapsed.withLock { $0 += duration }
    }
}

/// A launched Bouncer on a `ManualClock`, driven the way the app's polling loop drives it.
struct Scenario {
    let clock = ManualClock()
    var bouncer: Bouncer

    init(displayWidths: [Double] = [1512]) {
        bouncer = Bouncer(clock: clock)
        bouncer.handle(.displayWidthsChanged(displayWidths))
        bouncer.handle(.launchFinished)
    }

    var state: HiddenSectionState { bouncer.look.state }

    mutating func handle(_ event: Event) {
        bouncer.handle(event)
    }

    /// Lets time pass, then reports it as the app's polling loop would.
    mutating func wait(_ duration: Duration) {
        clock.advance(by: duration)
        bouncer.handle(.timePassed)
    }
}
