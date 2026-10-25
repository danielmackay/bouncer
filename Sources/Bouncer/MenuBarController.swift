import AppKit
import BouncerCore
import os

/// Owns Bouncer's status items. Feeds what happens into the core and applies the look
/// it returns; every decision belongs to `Bouncer`.
@MainActor
final class MenuBarController: NSObject {
    private static let log = Logger(subsystem: "dev.danielmackay.Bouncer", category: "MenuBar")

    /// Autosave names are how macOS remembers each item's position across launches and
    /// rebuilds. Renaming one makes macOS treat it as a brand-new item.
    private enum AutosaveName {
        static let toggle = "BouncerToggle"
        static let divider = "BouncerDivider"
        static func segment(_ index: Int) -> String { "BouncerDividerSegment\(index + 1)" }
    }

    private static let dividerWidth: CGFloat = 8
    private static let launchCheckInterval: Duration = .milliseconds(100)
    private static let launchTimeout: Duration = .seconds(5)

    private var bouncer = Bouncer()
    private let toggle: NSStatusItem
    private let divider: NSStatusItem
    private var segments: [NSStatusItem] = []
    private let menu: NSMenu

    override init() {
        // macOS places each new status item to the left of the ones created before it,
        // so creating right to left gives the first-launch order: segments, Divider, Toggle.
        toggle = Self.makeStatusItem(length: NSStatusItem.squareLength, autosaveName: AutosaveName.toggle)
        divider = Self.makeStatusItem(length: Self.dividerWidth, autosaveName: AutosaveName.divider)
        menu = NSMenu()
        super.init()

        configureToggle()
        configureMenu()
        divider.button?.setAccessibilityLabel("Bouncer Divider")

        observeSystem()
        bouncer.handle(.displayWidthsChanged(Self.displayWidths()))
        apply()
        waitForItemsThenFinishLaunch()
    }

    /// Shrinks every segment to zero so quitting never strands items in the System Overflow.
    func resetDivider() {
        for segment in segments {
            segment.length = 0
        }
    }

    // MARK: - Applying the core's look

    private func apply() {
        let look = bouncer.look
        growSegmentPool(to: look.dividerSegmentLengths.count)
        for (index, segment) in segments.enumerated() {
            // Extra segments left over from a display that has gone stay at zero; removing
            // them would make macOS forget their positions.
            let length = index < look.dividerSegmentLengths.count ? look.dividerSegmentLengths[index] : 0
            segment.length = CGFloat(length)
        }
        divider.button?.image = look.isDividerLineVisible ? Self.dividerLine : nil
        applyToggleIcon(for: look.state)
    }

    private func growSegmentPool(to count: Int) {
        while segments.count < count {
            let index = segments.count
            segments.append(Self.makeStatusItem(length: 0, autosaveName: AutosaveName.segment(index)))
        }
    }

    private func applyToggleIcon(for state: HiddenSectionState) {
        guard let button = toggle.button else {
            Self.log.error("The Toggle has no button, so its icon can't be updated")
            return
        }
        let (symbol, description) = switch state {
        case .collapsed: ("chevron.left", "Reveal hidden menu bar items")
        case .revealed: ("chevron.right", "Collapse hidden menu bar items")
        }
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: description)
        button.toolTip = description
    }

    // MARK: - Launch

    /// Collapsing before the status items are on screen gets lost, so launch only
    /// finishes once the Toggle and the Divider have been laid out in the menu bar.
    private func waitForItemsThenFinishLaunch() {
        Task { [weak self] in
            let deadline = ContinuousClock.now + Self.launchTimeout
            while let self, !self.itemsAreInPlace {
                guard ContinuousClock.now < deadline else {
                    Self.log.error("Status items weren't on screen after \(Self.launchTimeout); collapsing anyway")
                    break
                }
                do {
                    try await Task.sleep(for: Self.launchCheckInterval)
                } catch {
                    Self.log.info("Launch wait cancelled: \(error.localizedDescription, privacy: .public)")
                    return
                }
            }
            guard let self else { return }
            self.logItemPositions()
            self.send(.launchFinished)
        }
    }

    private var itemsAreInPlace: Bool {
        guard let toggleWindow = toggle.button?.window, let dividerWindow = divider.button?.window else {
            return false
        }
        // On macOS 27 a new status item's window starts as (0, 0, width, 0) with a screen
        // already attached; it has been placed in the menu bar once it has a height.
        return [toggleWindow, dividerWindow].allSatisfy { window in
            window.screen != nil && window.frame.width > 0 && window.frame.height > 0
        }
    }

    private func logItemPositions() {
        let describe: (String, NSStatusItem) -> String = { name, item in
            guard let frame = item.button?.window?.frame else { return "\(name)=offscreen" }
            return "\(name)=x\(Int(frame.minX))"
        }
        var parts = [describe("toggle", toggle), describe("divider", divider)]
        parts += segments.enumerated().map { describe("segment\($0.offset + 1)", $0.element) }
        Self.log.info("Status item positions at launch: \(parts.joined(separator: " "), privacy: .public)")
    }

    // MARK: - Events

    private func send(_ event: Event) {
        bouncer.handle(event)
        apply()
    }

    private func configureToggle() {
        guard let button = toggle.button else {
            Self.log.error("The Toggle has no button, so it can't be clicked")
            return
        }
        button.target = self
        button.action = #selector(toggleClicked(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func toggleClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else {
            Self.log.error("Toggle action fired without a current event; ignoring it")
            return
        }
        let wantsMenu = event.type == .rightMouseUp || event.modifierFlags.contains(.control)
        if wantsMenu {
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height + 4), in: sender)
        } else {
            send(.toggleClicked)
        }
    }

    private func observeSystem() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemWoke),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemWoke),
            name: NSWorkspace.screensDidWakeNotification,
            object: nil
        )
    }

    @objc private func screensChanged() {
        send(.displayWidthsChanged(Self.displayWidths()))
    }

    /// Displays can come back with different widths after sleep, and macOS may have
    /// re-laid out the menu bar, so re-measure and re-apply the look.
    @objc private func systemWoke() {
        send(.displayWidthsChanged(Self.displayWidths()))
    }

    private static func displayWidths() -> [Double] {
        NSScreen.screens.map { Double($0.frame.width) }
    }

    // MARK: - Menu

    private func configureMenu() {
        let hint = NSMenuItem(
            title: "Turn Items Off Completely in System Settings…",
            action: #selector(openMenuBarSettings),
            keyEquivalent: ""
        )
        hint.target = self
        hint.toolTip = "Disabled Items are a macOS feature; Bouncer can't reveal them."
        menu.addItem(hint)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Bouncer", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp
        menu.addItem(quit)
    }

    @objc private func openMenuBarSettings() {
        // The Menu Bar pane is provided by the Control Center settings extension.
        guard let url = URL(string: "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension") else {
            Self.log.error("The Menu Bar settings URL is malformed")
            return
        }
        if !NSWorkspace.shared.open(url) {
            Self.log.error("System Settings didn't open the Menu Bar pane")
            NSSound.beep()
        }
    }

    // MARK: - Drawing

    private static func makeStatusItem(length: CGFloat, autosaveName: String) -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: length)
        item.autosaveName = autosaveName
        return item
    }

    private static let dividerLine: NSImage = {
        let image = NSImage(size: NSSize(width: 1, height: 16), flipped: false) { rect in
            NSColor.black.setFill()
            rect.fill()
            return true
        }
        // Template so it follows the menu bar's light or dark appearance.
        image.isTemplate = true
        image.accessibilityDescription = "Divider"
        return image
    }()
}
