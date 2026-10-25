import Testing
import BouncerCore

@Suite("Launch")
struct LaunchTests {
    @Test("nothing is hidden until launch has finished")
    func revealedBeforeLaunchFinishes() {
        var bouncer = Bouncer()

        bouncer.handle(.displayWidthsChanged([1512]))

        #expect(bouncer.look.state == .revealed)
    }

    @Test("the Hidden Section starts Collapsed once launch has finished")
    func collapsedOnceLaunchFinishes() {
        var bouncer = Bouncer()

        bouncer.handle(.displayWidthsChanged([1512]))
        bouncer.handle(.launchFinished)

        #expect(bouncer.look.state == .collapsed)
    }
}
