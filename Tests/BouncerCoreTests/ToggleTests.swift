import Testing
import BouncerCore

@Suite("Toggle click")
struct ToggleTests {
    @Test("a click Reveals a Collapsed Hidden Section")
    func clickReveals() {
        var bouncer = Bouncer.launched(displayWidths: [1512])

        bouncer.handle(.toggleClicked)

        #expect(bouncer.look.state == .revealed)
    }

    @Test("a second click Collapses it again")
    func secondClickCollapses() {
        var bouncer = Bouncer.launched(displayWidths: [1512])

        bouncer.handle(.toggleClicked)
        bouncer.handle(.toggleClicked)

        #expect(bouncer.look.state == .collapsed)
    }
}
