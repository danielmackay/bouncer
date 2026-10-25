import Testing
import BouncerCore

/// The app creates every Divider segment at launch, because macOS places a status item
/// created later at the far left of the menu bar instead of next to the Divider.
@Suite("Divider segment pool")
struct SegmentPoolTests {
    @Test("before any display is known, the whole pool is there at zero length")
    func poolBeforeDisplays() {
        let bouncer = Bouncer()

        #expect(bouncer.look.dividerSegmentLengths == Array(repeating: 0, count: 16))
    }

    @Test("one display: three 752pt segments, the rest of the pool at zero")
    func unusedSegmentsAreZero() {
        let bouncer = Bouncer.launched(displayWidths: [1512])

        #expect(bouncer.look.dividerSegmentLengths == [752, 752, 752] + Array(repeating: 0, count: 13))
    }

    @Test("connecting a display doesn't change how many segments there are")
    func poolSizeStable() {
        var bouncer = Bouncer.launched(displayWidths: [1512])

        bouncer.handle(.displayWidthsChanged([1024, 6016]))

        #expect(bouncer.look.dividerSegmentLengths.count == 16)
    }

    @Test("a display mix that needs more than the pool still gets enough segments")
    func beyondThePool() {
        let bouncer = Bouncer.launched(displayWidths: [400, 6016])

        let lengths = bouncer.look.dividerSegmentLengths
        #expect(lengths.count > 16)
        #expect(lengths.allSatisfy { $0 == 196 })
    }
}
