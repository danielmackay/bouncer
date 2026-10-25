import Testing
import BouncerCore

@Suite("Auto-collapse")
struct AutoCollapseTests {
    @Test("Reveal, wait 10s, Collapsed")
    func collapsesAfterTimeout() {
        var scenario = Scenario()

        scenario.handle(.toggleClicked)
        scenario.wait(.seconds(10))

        #expect(scenario.state == .collapsed)
    }

    @Test("Reveal, wait 9s, still Revealed")
    func notBeforeTimeout() {
        var scenario = Scenario()

        scenario.handle(.toggleClicked)
        scenario.wait(.seconds(9))

        #expect(scenario.state == .revealed)
    }

    @Test("Reveal, wait 9s, pointer enters the zone, wait 30s, still Revealed")
    func pausedWhilePointerNearMenuBar() {
        var scenario = Scenario()

        scenario.handle(.toggleClicked)
        scenario.wait(.seconds(9))
        scenario.handle(.pointerEnteredMenuBarZone)
        scenario.wait(.seconds(30))

        #expect(scenario.state == .revealed)
    }

    @Test("…pointer leaves, wait 10s, Collapsed")
    func collapsesFullTimeoutAfterPointerLeaves() {
        var scenario = Scenario()

        scenario.handle(.toggleClicked)
        scenario.wait(.seconds(9))
        scenario.handle(.pointerEnteredMenuBarZone)
        scenario.wait(.seconds(30))
        scenario.handle(.pointerLeftMenuBarZone)
        scenario.wait(.seconds(10))

        #expect(scenario.state == .collapsed)
    }

    @Test("the countdown restarts from the full timeout, not where it paused")
    func restartsFromFullTimeout() {
        var scenario = Scenario()

        scenario.handle(.toggleClicked)
        scenario.wait(.seconds(9))
        scenario.handle(.pointerEnteredMenuBarZone)
        scenario.wait(.seconds(1))
        scenario.handle(.pointerLeftMenuBarZone)
        scenario.wait(.seconds(9))

        #expect(scenario.state == .revealed)
    }

    @Test("Reveal with the pointer on the Toggle: the countdown waits for it to leave")
    func revealedFromInsideTheZone() {
        var scenario = Scenario()

        scenario.handle(.pointerEnteredMenuBarZone)
        scenario.handle(.toggleClicked)
        scenario.wait(.seconds(30))
        #expect(scenario.state == .revealed)

        scenario.handle(.pointerLeftMenuBarZone)
        scenario.wait(.seconds(10))
        #expect(scenario.state == .collapsed)
    }

    @Test("a repeated 'pointer left' report doesn't push the Auto-collapse back")
    func repeatedLeaveDoesNotRestart() {
        var scenario = Scenario()

        scenario.handle(.toggleClicked)
        scenario.wait(.seconds(6))
        scenario.handle(.pointerLeftMenuBarZone)
        scenario.wait(.seconds(4))

        #expect(scenario.state == .collapsed)
    }
}
