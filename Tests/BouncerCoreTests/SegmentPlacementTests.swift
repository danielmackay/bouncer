import Testing
import BouncerCore

/// The Divider's segments are invisible, so a ⌘-drag can knock one out of the run next to
/// the visible Divider. Bouncer widens only the segments still in that run.
@Suite("Divider segment placement")
struct SegmentPlacementTests {
    /// Where macOS 27 lays out zero-length segments: 16pt apart going left from the Divider.
    static let dividerX = 1469.0
    static func runX(_ position: Int) -> Double { dividerX - 16 * Double(position) }

    @Test("segments dragged right of the Divider stay at zero; in-place ones carry the width")
    func rightOfDividerStaysZero() {
        var bouncer = Bouncer()
        bouncer.handle(.displayWidthsChanged([1512]))
        // Segments 2 and 3 sit among the Shown Section; the rest close up the run.
        var xs = [Self.runX(1), 1730, 1714]
        xs += (2...14).map(Self.runX)
        bouncer.handle(.dividerSegmentsObserved(dividerX: Self.dividerX, segmentXs: xs))

        bouncer.handle(.launchFinished)

        #expect(bouncer.look.state == .collapsed)
        #expect(bouncer.look.dividerSegmentLengths == [752, 0, 0, 752, 752] + Array(repeating: 0, count: 11))
    }

    @Test("a segment cut off from the run by another item stays at zero")
    func gapStaysZero() {
        var bouncer = Bouncer()
        bouncer.handle(.displayWidthsChanged([1512]))
        // Segment 1 sits beyond a Hidden Section item at the far end of the run.
        let xs = [Self.runX(15) - 40] + (1...15).map(Self.runX)
        bouncer.handle(.dividerSegmentsObserved(dividerX: Self.dividerX, segmentXs: xs))

        bouncer.handle(.launchFinished)

        #expect(bouncer.look.dividerSegmentLengths == [0, 752, 752, 752] + Array(repeating: 0, count: 12))
    }

    @Test("everything past a gap is out of place, even if evenly spaced")
    func pastTheGap() {
        var bouncer = Bouncer()
        bouncer.handle(.displayWidthsChanged([1512]))
        // Two in the run, then a 30pt item, then the rest stacked on as usual.
        let xs = (1...2).map(Self.runX) + (3...16).map { Self.runX($0) - 30 }
        bouncer.handle(.dividerSegmentsObserved(dividerX: Self.dividerX, segmentXs: xs))

        bouncer.handle(.launchFinished)

        #expect(bouncer.look.dividerSegmentLengths.filter { $0 > 0 }.count < 3)
    }

    @Test("too few segments in place: launch doesn't Collapse and the Toggle warns")
    func tooFewRefusesLaunch() {
        var bouncer = Bouncer()
        bouncer.handle(.displayWidthsChanged([1512]))
        bouncer.handle(.dividerSegmentsObserved(dividerX: Self.dividerX, segmentXs: Self.onlyTwoInPlace))

        bouncer.handle(.launchFinished)

        #expect(bouncer.look.state == .revealed)
        #expect(bouncer.look.dividerSegmentLengths.allSatisfy { $0 == 0 })
        #expect(bouncer.look.toggleIcon == .segmentsMisplacedWarning)
    }

    @Test("too few segments in place: a click doesn't Collapse")
    func tooFewRefusesClick() {
        var bouncer = Bouncer.launched(displayWidths: [1512])
        bouncer.handle(.toggleClicked)

        bouncer.handle(.dividerSegmentsObserved(dividerX: Self.dividerX, segmentXs: Self.onlyTwoInPlace))
        bouncer.handle(.toggleClicked)

        #expect(bouncer.look.state == .revealed)
        #expect(bouncer.look.toggleIcon == .segmentsMisplacedWarning)
    }

    @Test("a wider display needing more segments than are in place doesn't Collapse")
    func tooFewForNewDisplay() {
        var bouncer = Bouncer()
        bouncer.handle(.displayWidthsChanged([1512]))
        // Four in place: enough for one 1512pt display (3), not for 6016pt beside it (9).
        let xs = (1...4).map(Self.runX) + (5...16).map { Self.runX($0) - 40 }
        bouncer.handle(.dividerSegmentsObserved(dividerX: Self.dividerX, segmentXs: xs))
        bouncer.handle(.launchFinished)
        #expect(bouncer.look.state == .collapsed)

        bouncer.handle(.displayWidthsChanged([1512, 6016]))

        #expect(bouncer.look.state == .revealed)
        #expect(bouncer.look.dividerSegmentLengths.allSatisfy { $0 == 0 })
        #expect(bouncer.look.toggleIcon == .segmentsMisplacedWarning)
    }

    @Test("a misplaced Toggle's warning wins over misplaced segments")
    func toggleWarningWins() {
        var bouncer = Bouncer()
        bouncer.handle(.displayWidthsChanged([1512]))
        bouncer.handle(.dividerSegmentsObserved(dividerX: Self.dividerX, segmentXs: Self.onlyTwoInPlace))
        bouncer.handle(.toggleSectionObserved(.hidden))

        #expect(bouncer.look.toggleIcon == .warning)
    }

    /// Two segments next to the Divider and the other fourteen beyond a 30pt item.
    static let onlyTwoInPlace = (1...2).map(runX) + (3...16).map { runX($0) - 30 }
}
