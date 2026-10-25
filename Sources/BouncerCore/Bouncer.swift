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
    /// The pointer moved onto the menu bar, or into the band just below it where a
    /// Menu Bar Item's menu opens, on whichever display it is on.
    case pointerEnteredMenuBarZone
    /// The pointer moved out of that zone.
    case pointerLeftMenuBarZone
    /// The user picked a new Auto-collapse timeout. It applies from the next countdown.
    case autoCollapseTimeoutChanged(AutoCollapseTimeout)
}

/// How the menu bar should look. The AppKit layer applies this verbatim.
public struct MenuBarLook: Sendable, Equatable {
    public var state: HiddenSectionState
    /// Length in points of each Divider segment, in creation order. The count depends
    /// only on the attached displays, so it is the same whether Revealed or Collapsed.
    public var dividerSegmentLengths: [Double]
    /// Whether the visible Divider draws its thin line.
    public var isDividerLineVisible: Bool
}

/// Bouncer's decisions: feed it events, read back the look.
public struct Bouncer: Sendable {
    private var state: HiddenSectionState = .revealed
    private var displays: DividerSizing?
    private let clock: any BouncerClock
    private var autoCollapse = AutoCollapseCountdown()

    public init(clock: any BouncerClock = SystemClock()) {
        self.clock = clock
    }

    public var look: MenuBarLook {
        let sizing = displays ?? .none
        return MenuBarLook(
            state: state,
            dividerSegmentLengths: Array(
                repeating: state == .collapsed ? sizing.segmentLength : 0,
                count: sizing.segmentCount
            ),
            isDividerLineVisible: state == .revealed
        )
    }

    public mutating func handle(_ event: Event) {
        switch event {
        case .launchFinished:
            state = .collapsed
        case .toggleClicked:
            state = state == .revealed ? .collapsed : .revealed
            if state == .revealed {
                autoCollapse.arm(now: clock.now)
            } else {
                autoCollapse.disarm()
            }
        case .displayWidthsChanged(let widths):
            // Mid-reconfiguration and around sleep, the system can briefly report no
            // screens. Keeping the last real sizing stops a Collapsed Hidden Section
            // from flashing into view during that gap.
            if let sizing = DividerSizing(displayWidths: widths) {
                displays = sizing
            }
        case .timePassed:
            if state == .revealed, autoCollapse.isDue(now: clock.now) {
                state = .collapsed
            }
        case .pointerEnteredMenuBarZone:
            autoCollapse.pointerEntered()
        case .pointerLeftMenuBarZone:
            autoCollapse.pointerLeft(now: clock.now)
        case .autoCollapseTimeoutChanged(let timeout):
            autoCollapse.timeout = timeout
        }
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
