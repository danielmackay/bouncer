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

/// The countdown from Reveal to Auto-collapse.
struct AutoCollapseCountdown: Sendable {
    private let timeout: Duration = .seconds(10)
    private var deadline: Duration?

    /// Starts a countdown from the full timeout.
    mutating func start(now: Duration) {
        deadline = now + timeout
    }

    mutating func cancel() {
        deadline = nil
    }

    /// True once, when the countdown runs out; the countdown is then over.
    mutating func isDue(now: Duration) -> Bool {
        guard let deadline, now >= deadline else { return false }
        self.deadline = nil
        return true
    }
}
