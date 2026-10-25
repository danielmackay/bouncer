import Testing
import BouncerCore

/// Collapsing while the Toggle sits in the Hidden Section would hide the only way to
/// Reveal again, so Bouncer refuses and warns until the Toggle is dragged back.
@Suite("Misplaced Toggle")
struct MisplacedToggleTests {
    @Test("launch doesn't Collapse while the Toggle is in the Hidden Section")
    func launchRefuses() {
        var bouncer = Bouncer()

        bouncer.handle(.displayWidthsChanged([1512]))
        bouncer.handle(.toggleSectionObserved(.hidden))
        bouncer.handle(.launchFinished)

        #expect(bouncer.look.state == .revealed)
    }

    @Test("a click doesn't Collapse after the Toggle is dragged into the Hidden Section")
    func clickRefuses() {
        var bouncer = Bouncer.launched(displayWidths: [1512])
        bouncer.handle(.toggleClicked)

        bouncer.handle(.toggleSectionObserved(.hidden))
        bouncer.handle(.toggleClicked)

        #expect(bouncer.look.state == .revealed)
    }
}
