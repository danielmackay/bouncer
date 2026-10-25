/// Whether the Hidden Section's Menu Bar Items are in the menu bar or pushed out of it.
public enum HiddenSectionState: Sendable, Equatable {
    case revealed
    case collapsed
}

/// Something that happened that Bouncer may need to react to. The AppKit layer reports
/// these; it never decides anything itself.
public enum Event: Sendable, Equatable {
    case launchFinished
    case toggleClicked
    /// Widths in points of every attached display, in any order.
    case displayWidthsChanged([Double])
}

/// How the menu bar should look. The AppKit layer applies this verbatim.
public struct MenuBarLook: Sendable, Equatable {
    public var state: HiddenSectionState
}

/// Bouncer's decisions: feed it events, read back the look.
public struct Bouncer: Sendable {
    public private(set) var look = MenuBarLook(state: .revealed)

    public init() {}

    public mutating func handle(_ event: Event) {
        switch event {
        case .toggleClicked:
            look.state = look.state == .revealed ? .collapsed : .revealed
        case .launchFinished:
            look.state = .collapsed
        case .displayWidthsChanged:
            break
        }
    }
}
