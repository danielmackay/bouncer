import Testing
import BouncerCore

@Suite("Auto-collapse timeout preference")
struct AutoCollapsePreferenceTests {
    @Test("nothing stored yet means the 10s default")
    func nothingStoredIsDefault() {
        #expect(AutoCollapseTimeout(storedSeconds: nil) == .after(.seconds(10)))
    }

    @Test("stored 0 means Off")
    func zeroIsOff() {
        #expect(AutoCollapseTimeout(storedSeconds: 0) == .off)
    }

    @Test("stored 30 means 30s")
    func storedChoiceIsUsed() {
        #expect(AutoCollapseTimeout(storedSeconds: 30) == .after(.seconds(30)))
    }

    @Test("Off is stored as 0, 60s as 60")
    func storedSeconds() {
        #expect(AutoCollapseTimeout.off.storedSeconds == 0)
        #expect(AutoCollapseTimeout.after(.seconds(60)).storedSeconds == 60)
    }

    @Test("Settings offers Off, 5, 10, 30 and 60 seconds, and each survives being stored")
    func choicesRoundTrip() {
        #expect(AutoCollapseTimeout.choices.map(\.storedSeconds) == [0, 5, 10, 30, 60])
        for choice in AutoCollapseTimeout.choices {
            #expect(AutoCollapseTimeout(storedSeconds: choice.storedSeconds) == choice)
        }
    }

    @Test("a stored value that isn't one of the choices means the 10s default", arguments: [7, -5, 3600])
    func unknownValueIsDefault(seconds: Int) {
        #expect(AutoCollapseTimeout(storedSeconds: seconds) == .after(.seconds(10)))
    }
}
