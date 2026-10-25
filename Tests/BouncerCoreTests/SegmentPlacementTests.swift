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
}
