import Testing
import BouncerCore

/// macOS 27 discards a status item whose length reaches half the display, and the
/// Divider only pushes the Hidden Section into the System Overflow once it is wider
/// than the whole menu bar (ADR 0001).
@Suite("Divider sizing while Collapsed")
struct DividerSizingTests {
    @Test("one display: every segment is just under half its width, together wider than it")
    func oneDisplay() {
        let bouncer = Bouncer.launched(displayWidths: [1512])

        expectHides(bouncer.look, narrowest: 1512, widest: 1512)
    }

    @Test("the notched built-in display gets three 752pt segments")
    func notchedDisplayExample() {
        let bouncer = Bouncer.launched(displayWidths: [1512])

        #expect(bouncer.look.dividerSegmentLengths == [752, 752, 752])
    }

    @Test("two mixed displays: sized by the narrowest, wide enough for the widest")
    func twoMixedDisplays() {
        let bouncer = Bouncer.launched(displayWidths: [2048, 1512])

        expectHides(bouncer.look, narrowest: 1512, widest: 2048)
    }

    @Test("a very wide display next to a narrow one needs more segments")
    func veryWideAndNarrow() {
        let bouncer = Bouncer.launched(displayWidths: [1024, 5120])

        expectHides(bouncer.look, narrowest: 1024, widest: 5120)
    }

    @Test("connecting a wider display re-sizes the Divider and stays Collapsed")
    func connectingDisplay() {
        var bouncer = Bouncer.launched(displayWidths: [1512])

        bouncer.handle(.displayWidthsChanged([1512, 3008]))

        #expect(bouncer.look.state == .collapsed)
        expectHides(bouncer.look, narrowest: 1512, widest: 3008)
    }

    @Test("disconnecting the narrow display lets the segments grow")
    func disconnectingDisplay() {
        var bouncer = Bouncer.launched(displayWidths: [1512, 2048])

        bouncer.handle(.displayWidthsChanged([2048]))

        #expect(bouncer.look.state == .collapsed)
        expectHides(bouncer.look, narrowest: 2048, widest: 2048)
    }

    @Test("a moment with no displays keeps the last known sizing")
    func noDisplaysKeepsLastSizing() {
        var bouncer = Bouncer.launched(displayWidths: [1512])

        bouncer.handle(.displayWidthsChanged([]))

        #expect(bouncer.look.dividerSegmentLengths == [752, 752, 752])
    }

    @Test("nonsense widths are ignored")
    func nonsenseWidthsIgnored() {
        var bouncer = Bouncer.launched(displayWidths: [1512])

        bouncer.handle(.displayWidthsChanged([0, -40, .nan, .infinity]))

        #expect(bouncer.look.dividerSegmentLengths == [752, 752, 752])
    }

    @Test("Revealing sets every segment to zero length")
    func revealedSegmentsAreZero() {
        var bouncer = Bouncer.launched(displayWidths: [1512, 2048])

        bouncer.handle(.toggleClicked)

        #expect(!bouncer.look.dividerSegmentLengths.isEmpty)
        #expect(bouncer.look.dividerSegmentLengths.allSatisfy { $0 == 0 })
    }

    @Test("the segment count doesn't change between Collapsed and Revealed")
    func segmentCountStable() {
        var bouncer = Bouncer.launched(displayWidths: [1512, 2048])
        let collapsedCount = bouncer.look.dividerSegmentLengths.count

        bouncer.handle(.toggleClicked)

        #expect(bouncer.look.dividerSegmentLengths.count == collapsedCount)
    }
}

private func expectHides(
    _ look: MenuBarLook,
    narrowest: Double,
    widest: Double,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    let lengths = look.dividerSegmentLengths
    #expect(!lengths.isEmpty, sourceLocation: sourceLocation)
    for length in lengths {
        #expect(length < narrowest / 2, "segment \(length) reaches half of \(narrowest)", sourceLocation: sourceLocation)
        #expect(length > narrowest / 2 - 10, "segment \(length) isn't just under half of \(narrowest)", sourceLocation: sourceLocation)
    }
    #expect(lengths.reduce(0, +) > widest, "segments total \(lengths.reduce(0, +)), not wider than \(widest)", sourceLocation: sourceLocation)
}
