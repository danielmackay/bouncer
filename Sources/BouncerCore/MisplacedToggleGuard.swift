/// Which side of the visible Divider the Toggle sits on, as read from the menu bar.
public enum ToggleSection: Sendable, Equatable {
    case shown
    case hidden
}

/// The rule that stops Bouncer hiding its own Toggle. `Bouncer` routes every Collapse
/// through it, so the rule can change without touching the rest of the core.
struct MisplacedToggleGuard: Sendable, Equatable {
    /// Shown until the AppKit layer says otherwise: on first launch Bouncer creates the
    /// Toggle right of the Divider, and an unread order shouldn't block collapsing.
    var toggleSection: ToggleSection = .shown

    /// Collapsing with the Toggle in the Hidden Section would push it into the System
    /// Overflow too, leaving no way to Reveal.
    var allowsCollapse: Bool { toggleSection == .shown }

    /// Explains why collapsing isn't working, for as long as it isn't.
    var showsWarning: Bool { toggleSection == .hidden }
}
