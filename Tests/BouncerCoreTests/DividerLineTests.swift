import Testing
import BouncerCore

@Suite("Divider line")
struct DividerLineTests {
    @Test("the line shows while Revealed, so there's somewhere to ⌘-drag items")
    func visibleWhileRevealed() {
        var bouncer = Bouncer.launched(displayWidths: [1512])

        bouncer.handle(.toggleClicked)

        #expect(bouncer.look.isDividerLineVisible)
    }

    @Test("the line is hidden while Collapsed")
    func hiddenWhileCollapsed() {
        let bouncer = Bouncer.launched(displayWidths: [1512])

        #expect(!bouncer.look.isDividerLineVisible)
    }

    @Test("the line hides again when the Hidden Section is Collapsed by a click")
    func hiddenAfterClickCollapses() {
        var bouncer = Bouncer.launched(displayWidths: [1512])

        bouncer.handle(.toggleClicked)
        bouncer.handle(.toggleClicked)

        #expect(!bouncer.look.isDividerLineVisible)
    }
}
