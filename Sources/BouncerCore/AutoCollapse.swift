/// Where Bouncer reads the time from. Injected so tests move time by hand instead of
/// sleeping.
public protocol BouncerClock: Sendable {
    /// Time since an arbitrary fixed origin. Must never go backwards.
    var now: Duration { get }
}

/// The real clock. Continuous rather than suspending, so time spent asleep counts: a
/// Hidden Section Revealed before the lid closed is due to Auto-collapse on wake.
public struct SystemClock: BouncerClock {
    private let origin = ContinuousClock.now

    public init() {}

    public var now: Duration { ContinuousClock.now - origin }
}

/// The countdown from Reveal to Auto-collapse. It runs only while the pointer is away
/// from the menu bar, and every time it starts it starts from the full timeout.
struct AutoCollapseCountdown: Sendable {
    private let timeout: Duration = .seconds(10)
    /// Between a Reveal and the next Collapse, whether or not the clock is running.
    private var isArmed = false
    private var isPointerInZone = false
    private var deadline: Duration?

    /// The Hidden Section was just Revealed.
    mutating func arm(now: Duration) {
        isArmed = true
        restart(now: now)
    }

    /// The Hidden Section was Collapsed, so nothing is pending any more.
    mutating func disarm() {
        isArmed = false
        deadline = nil
    }

    /// Pauses the countdown, so a menu opened from a Revealed item can't be collapsed
    /// out from under the pointer.
    mutating func pointerEntered() {
        isPointerInZone = true
        deadline = nil
    }

    mutating func pointerLeft(now: Duration) {
        // The app may report the same position more than once; only a real exit from
        // the zone restarts the countdown, or repeated reports would keep deferring it.
        guard isPointerInZone else { return }
        isPointerInZone = false
        restart(now: now)
    }

    /// True once, when the countdown runs out; the countdown is then over.
    mutating func isDue(now: Duration) -> Bool {
        guard let deadline, now >= deadline else { return false }
        disarm()
        return true
    }

    private mutating func restart(now: Duration) {
        deadline = isArmed && !isPointerInZone ? now + timeout : nil
    }
}
