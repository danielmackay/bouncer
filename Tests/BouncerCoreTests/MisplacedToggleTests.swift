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

    @Test("no warning while the Toggle is in the Shown Section")
    func noWarningWhenShown() {
        var bouncer = Bouncer.launched(displayWidths: [1512])

        bouncer.handle(.toggleSectionObserved(.shown))

        #expect(bouncer.look.toggleIcon != .warning)
    }

    @Test("the Toggle warns while it's in the Hidden Section")
    func warnsWhenHidden() {
        var bouncer = Bouncer.launched(displayWidths: [1512])
        bouncer.handle(.toggleClicked)

        bouncer.handle(.toggleSectionObserved(.hidden))

        #expect(bouncer.look.toggleIcon == .warning)
    }

    @Test("dragging the Toggle back clears the warning and a click Collapses again")
    func draggingBackRestoresCollapsing() {
        var bouncer = Bouncer.launched(displayWidths: [1512])
        bouncer.handle(.toggleClicked)
        bouncer.handle(.toggleSectionObserved(.hidden))
        bouncer.handle(.toggleClicked)

        bouncer.handle(.toggleSectionObserved(.shown))
        bouncer.handle(.toggleClicked)

        #expect(bouncer.look.toggleIcon != .warning)
        #expect(bouncer.look.state == .collapsed)
    }

    @Test("after a refused launch, dragging the Toggle back lets a click Collapse")
    func draggingBackAfterRefusedLaunch() {
        var bouncer = Bouncer()
        bouncer.handle(.displayWidthsChanged([1512]))
        bouncer.handle(.toggleSectionObserved(.hidden))
        bouncer.handle(.launchFinished)

        bouncer.handle(.toggleSectionObserved(.shown))
        bouncer.handle(.toggleClicked)

        #expect(bouncer.look.state == .collapsed)
        #expect(bouncer.look.dividerSegmentLengths == [752, 752, 752])
    }
}
