/// Whether the Hidden Section's Menu Bar Items are in the menu bar or pushed out of it.
public enum HiddenSectionState: Sendable, Equatable {
    case revealed
    case collapsed
}

/// Something that happened that Bouncer may need to react to. The AppKit layer reports
/// these; it never decides anything itself.
public enum Event: Sendable, Equatable {
    /// Bouncer's own status items are in place in the menu bar.
    case launchFinished
    /// A left-click on the Toggle.
    case toggleClicked
    /// Widths in points of every attached display, in any order. Sent at launch and
    /// whenever the screen configuration changes.
    case displayWidthsChanged([Double])
    /// Time has moved on; Bouncer reads how far from its clock. The app sends this from
    /// a polling loop.
    case timePassed
    /// The pointer is on the menu bar, or in the band just below it where a Menu Bar
    /// Item's menu opens, on whichever display it is on. The app may repeat this and
    /// `pointerLeftMenuBarZone` on every poll; only a change of zone counts.
    case pointerEnteredMenuBarZone
    /// The pointer is outside that zone.
    case pointerLeftMenuBarZone
    /// The user picked a new Auto-collapse timeout. It applies from the next countdown.
    case autoCollapseTimeoutChanged(AutoCollapseTimeout)
    /// Which section the Toggle is in. Sent once the order can be read at launch and
    /// again whenever Bouncer's status items may have moved, such as after a ⌘-drag.
    case toggleSectionObserved(ToggleSection)
    /// The left edges of the visible Divider and of every Divider segment, in creation
    /// order, all read on the same display. Sent at the same points as
    /// `toggleSectionObserved`; Bouncer decides whether the reading can be trusted.
    case dividerSegmentsObserved(dividerX: Double, segmentXs: [Double])
    /// Bouncer is about to quit. Its status items vanish with the process, but a Collapsed
    /// Divider must shrink first or macOS can leave the Hidden Section in the System Overflow.
    case terminating
}

/// What the Toggle's icon shows. The AppKit layer maps each case to a symbol and tooltip.
public enum ToggleIcon: Sendable, Equatable {
    case collapsed
    case revealed
    /// The Toggle sits in the Hidden Section, so a click can't Collapse. It replaces the
    /// state icon in either state: explaining why collapsing isn't working matters more.
    case warning
    /// Too few Divider segments are left next to the Divider to Collapse over the widest
    /// display, so a click can't Collapse. Replaces the state icon like `warning`.
    case segmentsMisplacedWarning
}

/// How the menu bar should look. The AppKit layer applies this verbatim.
public struct MenuBarLook: Sendable, Equatable {
    public var state: HiddenSectionState
    /// Length in points of each Divider segment, in creation order. Segments the displays
    /// don't need are 0. The count is `Bouncer.dividerSegmentPoolSize` unless the displays
    /// need more, and is the same whether Revealed or Collapsed.
    public var dividerSegmentLengths: [Double]
    /// Whether the visible Divider draws its thin line.
    public var isDividerLineVisible: Bool
    public var toggleIcon: ToggleIcon
}

/// Bouncer's decisions: feed it events, read back the look.
public struct Bouncer: Sendable {
    /// How many Divider segments the look always covers, so the app can create them all at
    /// launch in first-launch order. 16 is enough for a 6016pt display next to one as
    /// narrow as 760pt; a mix needing more still gets them, as extra entries in the look.
    public static let dividerSegmentPoolSize = 16

    private var state: HiddenSectionState = .revealed
    private var sizing: DividerSizing?
    private let clock: any BouncerClock
    private var autoCollapse = AutoCollapseCountdown()
    private var toggleGuard = MisplacedToggleGuard()
    private var placement = DividerSegmentPlacement()
    /// Final: once quitting, nothing may Collapse again before the process exits.
    private var isTerminating = false

    public init(clock: any BouncerClock = SystemClock()) {
        self.clock = clock
    }

    public var look: MenuBarLook {
        MenuBarLook(
            state: state,
            dividerSegmentLengths: dividerSegmentLengths,
            isDividerLineVisible: state == .revealed,
            toggleIcon: toggleIcon
        )
    }

    /// The first in-place segments the displays need carry the length; every other
    /// segment, out of place or unneeded, stays at zero.
    private var dividerSegmentLengths: [Double] {
        let sizing = self.sizing ?? .none
        let length = state == .collapsed ? sizing.segmentLength : 0
        var lengths = Array(repeating: 0.0, count: segmentSlotCount)
        for index in carrierSegments {
            lengths[index] = length
        }
        return lengths
    }

    private var segmentSlotCount: Int {
        max(Self.dividerSegmentPoolSize, (sizing ?? .none).segmentCount)
    }

    /// The segments that widen on Collapse: the in-place ones nearest the start of the
    /// pool, as many as the displays need, or fewer when not enough are in place.
    private var carrierSegments: [Int] {
        Array((0..<segmentSlotCount).filter(placement.isInPlace).prefix((sizing ?? .none).segmentCount))
    }

    /// Fewer in-place segments than the displays need would leave the Divider narrower than
    /// the widest display, so macOS could fit the Hidden Section beside it instead of
    /// moving it into the System Overflow.
    private var hasEnoughSegmentsInPlace: Bool {
        carrierSegments.count == (sizing ?? .none).segmentCount
    }

    private var toggleIcon: ToggleIcon {
        // The misplaced Toggle comes first because the user can fix it by dragging it
        // back; misplaced segments are invisible.
        if toggleGuard.showsWarning { return .warning }
        if !hasEnoughSegmentsInPlace { return .segmentsMisplacedWarning }
        return state == .collapsed ? .collapsed : .revealed
    }

    public mutating func handle(_ event: Event) {
        switch event {
        case .launchFinished:
            collapse()
        case .toggleClicked:
            if state == .revealed {
                collapse()
            } else {
                state = .revealed
                autoCollapse.arm(now: clock.now)
            }
        case .displayWidthsChanged(let widths):
            // Mid-reconfiguration and around sleep, the system can briefly report no
            // screens. Keeping the last real sizing stops a Collapsed Hidden Section
            // from flashing into view during that gap.
            if let newSizing = DividerSizing(displayWidths: widths) {
                sizing = newSizing
            }
            // A wider display can need more segments than are in place. A Collapse that
            // can't cover it would leave the Hidden Section half on screen, so Reveal.
            if state == .collapsed, !hasEnoughSegmentsInPlace {
                state = .revealed
            }
        case .timePassed:
            // isDue ends the countdown whether or not the guard lets this Collapse
            // through, so a skipped Auto-collapse isn't retried: dragging the Toggle back
            // shouldn't hide items the moment it lands. The next Reveal starts a new one.
            if state == .revealed, autoCollapse.isDue(now: clock.now) {
                collapse()
            }
        case .pointerEnteredMenuBarZone:
            autoCollapse.pointerEntered()
        case .pointerLeftMenuBarZone:
            autoCollapse.pointerLeft(now: clock.now)
        case .autoCollapseTimeoutChanged(let timeout):
            autoCollapse.timeout = timeout
        case .toggleSectionObserved(let section):
            toggleGuard.toggleSection = section
        case .dividerSegmentsObserved(let dividerX, let segmentXs):
            placement.observe(dividerX: dividerX, segmentXs: segmentXs)
        case .terminating:
            isTerminating = true
            state = .revealed
            autoCollapse.disarm()
        }
    }

    /// Every route to Collapsed goes through here, so the misplaced-Toggle guard, the
    /// segment placement and quitting apply to all of them.
    private mutating func collapse() {
        guard !isTerminating, toggleGuard.allowsCollapse, hasEnoughSegmentsInPlace else { return }
        state = .collapsed
        autoCollapse.disarm()
    }
}

/// How many Divider segments there are and how long each is while Collapsed.
struct DividerSizing: Sendable, Equatable {
    /// How far under half the narrowest display each segment stays. macOS 27 discards a
    /// status item whose length reaches half the display; the margin absorbs rounding
    /// between points and pixels.
    static let marginBelowHalf: Double = 4

    static let none = DividerSizing(segmentLength: 0, segmentCount: 0)

    let segmentLength: Double
    let segmentCount: Int

    private init(segmentLength: Double, segmentCount: Int) {
        self.segmentLength = segmentLength
        self.segmentCount = segmentCount
    }

    /// Nil when no width is usable, so callers keep whatever sizing they had.
    init?(displayWidths: [Double]) {
        let usable = displayWidths.filter { $0.isFinite && $0 > 0 }
        guard let narrowest = usable.min(), let widest = usable.max() else { return nil }

        let length = (narrowest / 2).rounded(.down) - Self.marginBelowHalf
        guard length > 0 else { return nil }

        // Strictly wider than the widest display, so macOS can't fit the Divider and the
        // Hidden Section side by side on any of them.
        let count = Int((widest / length).rounded(.down)) + 1
        self.init(segmentLength: length, segmentCount: count)
    }
}
