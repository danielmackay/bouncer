/// Which side of the visible Divider the Toggle sits on, as read from the menu bar.
public enum ToggleSection: Sendable, Equatable {
    case shown
    case hidden
}

/// The rule that stops Bouncer hiding its own Toggle. It is provisional, so it lives
/// here on its own: changing or dropping it shouldn't touch the rest of the core.
struct MisplacedToggleGuard: Sendable, Equatable {
    /// Shown until the AppKit layer says otherwise: on first launch Bouncer creates the
    /// Toggle right of the Divider, and an unread order shouldn't block collapsing.
    var toggleSection: ToggleSection = .shown

    /// Collapsing with the Toggle in the Hidden Section would push it into the System
    /// Overflow too, leaving no way to Reveal.
    var allowsCollapse: Bool { toggleSection == .shown }
}
