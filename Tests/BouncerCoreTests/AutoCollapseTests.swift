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
}
