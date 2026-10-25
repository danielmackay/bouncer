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

    @Test("Reveal, wait 5s, Collapse by hand, Reveal with the pointer in the zone, wait 30s, still Revealed")
    func manualCollapseCancels() {
        var scenario = Scenario()

        scenario.handle(.toggleClicked)
        scenario.wait(.seconds(5))
        scenario.handle(.toggleClicked)
        scenario.handle(.pointerEnteredMenuBarZone)
        scenario.handle(.toggleClicked)
        scenario.wait(.seconds(30))

        #expect(scenario.state == .revealed)
    }

    @Test("a Collapsed Hidden Section stays Collapsed when the pointer comes and goes")
    func pointerDoesNotRevealOrCollapse() {
        var scenario = Scenario()

        scenario.handle(.pointerEnteredMenuBarZone)
        scenario.handle(.pointerLeftMenuBarZone)
        scenario.wait(.seconds(30))

        #expect(scenario.state == .collapsed)
    }
}

@Suite("Auto-collapse timeout")
struct AutoCollapseTimeoutTests {
    @Test("timeout Off: Reveal, wait an hour, still Revealed")
    func offNeverCollapses() {
        var scenario = Scenario()

        scenario.handle(.autoCollapseTimeoutChanged(.off))
        scenario.handle(.toggleClicked)
        scenario.wait(.seconds(3600))

        #expect(scenario.state == .revealed)
    }

    @Test("timeout 5s: Reveal, wait 5s, Collapsed")
    func shorterTimeout() {
        var scenario = Scenario()

        scenario.handle(.autoCollapseTimeoutChanged(.after(.seconds(5))))
        scenario.handle(.toggleClicked)
        scenario.wait(.seconds(5))

        #expect(scenario.state == .collapsed)
    }

    @Test("timeout Off with the pointer leaving the zone still never collapses")
    func offIgnoresPointer() {
        var scenario = Scenario()

        scenario.handle(.autoCollapseTimeoutChanged(.off))
        scenario.handle(.pointerEnteredMenuBarZone)
        scenario.handle(.toggleClicked)
        scenario.handle(.pointerLeftMenuBarZone)
        scenario.wait(.seconds(3600))

        #expect(scenario.state == .revealed)
    }

    @Test("changing the timeout mid-countdown leaves the running countdown alone")
    func changeMidCountdownWaitsForNextCountdown() {
        var scenario = Scenario()

        scenario.handle(.toggleClicked)
        scenario.wait(.seconds(2))
        scenario.handle(.autoCollapseTimeoutChanged(.after(.seconds(60))))
        scenario.wait(.seconds(8))

        #expect(scenario.state == .collapsed)
    }

    @Test("a new timeout applies to the next countdown, including one restarted by the pointer leaving")
    func changeAppliesToNextCountdown() {
        var scenario = Scenario()

        scenario.handle(.toggleClicked)
        scenario.wait(.seconds(2))
        scenario.handle(.autoCollapseTimeoutChanged(.after(.seconds(30))))
        scenario.handle(.pointerEnteredMenuBarZone)
        scenario.handle(.pointerLeftMenuBarZone)
        scenario.wait(.seconds(29))
        #expect(scenario.state == .revealed)

        scenario.wait(.seconds(1))
        #expect(scenario.state == .collapsed)
    }

    @Test("turning the timeout Off applies from the next Reveal")
    func offAppliesToNextReveal() {
        var scenario = Scenario()

        scenario.handle(.toggleClicked)
        scenario.handle(.autoCollapseTimeoutChanged(.off))
        scenario.handle(.toggleClicked)
        scenario.handle(.toggleClicked)
        scenario.wait(.seconds(3600))

        #expect(scenario.state == .revealed)
    }

    @Test("a zero or negative timeout means Off rather than collapsing at once")
    func nonPositiveTimeoutIsOff() {
        var scenario = Scenario()

        scenario.handle(.autoCollapseTimeoutChanged(.after(.zero)))
        scenario.handle(.toggleClicked)
        scenario.wait(.seconds(3600))
        #expect(scenario.state == .revealed)

        scenario.handle(.autoCollapseTimeoutChanged(.after(.seconds(-5))))
        scenario.handle(.toggleClicked)
        scenario.handle(.toggleClicked)
        scenario.wait(.seconds(3600))
        #expect(scenario.state == .revealed)
    }

    @Test("the default timeout is 10 seconds")
    func defaultIsTenSeconds() {
        #expect(AutoCollapseTimeout.default == .after(.seconds(10)))
    }
}
