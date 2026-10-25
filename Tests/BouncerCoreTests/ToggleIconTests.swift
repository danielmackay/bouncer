import Testing
import BouncerCore

/// The Toggle's icon shows the Hidden Section's state, unless a click can't Collapse at all.
@Suite("Toggle icon")
struct ToggleIconTests {
    @Test("Collapsed shows the Collapsed icon")
    func collapsed() {
        let bouncer = Bouncer.launched(displayWidths: [1512])

        #expect(bouncer.look.toggleIcon == .collapsed)
    }

    @Test("Revealed shows the Revealed icon")
    func revealed() {
        var bouncer = Bouncer.launched(displayWidths: [1512])

        bouncer.handle(.toggleClicked)

        #expect(bouncer.look.toggleIcon == .revealed)
    }

    @Test("the warning wins over the state while the Toggle is in the Hidden Section")
    func warningWins() {
        var bouncer = Bouncer.launched(displayWidths: [1512])
        bouncer.handle(.toggleClicked)

        bouncer.handle(.toggleSectionObserved(.hidden))

        #expect(bouncer.look.toggleIcon == .warning)
    }
}
