import Testing
import BouncerCore

/// Quitting while Collapsed must not strand the Hidden Section in the System Overflow.
@Suite("Quit")
struct QuitTests {
    @Test("quitting while Collapsed shrinks every segment to zero")
    func quittingZeroesSegments() {
        var bouncer = Bouncer.launched(displayWidths: [1512])

        bouncer.handle(.terminating)

        #expect(!bouncer.look.dividerSegmentLengths.isEmpty)
        #expect(bouncer.look.dividerSegmentLengths.allSatisfy { $0 == 0 })
    }

    @Test("nothing Collapses the Hidden Section again once Bouncer is quitting")
    func staysZeroAfterQuitting() {
        var scenario = Scenario()
        scenario.handle(.toggleClicked)

        scenario.handle(.terminating)
        scenario.wait(.seconds(10))
        scenario.handle(.toggleClicked)
        scenario.handle(.toggleClicked)

        #expect(scenario.bouncer.look.dividerSegmentLengths.allSatisfy { $0 == 0 })
    }
}
