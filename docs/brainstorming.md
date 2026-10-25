# Bouncer: brainstorming

A simple macOS menu bar manager, in the spirit of Bartender. Bouncer decides who gets into the menu bar.

## Goals

- Choose which menu bar items are always shown.
- Choose which items are hidden but can be revealed with a click.
- Keep it simple.

## The core constraint

macOS has no public API for controlling other apps' menu bar items. An app can create and manage only its own `NSStatusItem`s. Every menu bar manager works around this, and the workaround chosen shapes the whole app.

## Approaches, simplest first

### 1. The divider trick (Hidden Bar, Dozer)

- Bouncer adds two status items: a visible toggle (a chevron) and an invisible divider beside it.
- To hide items, set the divider's `length` to something huge (about 10,000pt). Every item to the left of the divider is pushed off-screen. To reveal them, shrink it back to a few points.
- The user decides what's hidden by ⌘-dragging icons to either side of the divider. macOS remembers those positions itself, so Bouncer stores nothing.
- No permissions, no private APIs. A few hundred lines of Swift.
- Downside: the "configuration" is ⌘-dragging, not a settings screen.

### 2. Divider plus a settings UI (Ice)

- Adds a settings window that lists every menu bar item with its icon and a shown/hidden toggle.
- To find the items, enumerate menu bar windows with `CGWindowListCopyWindowInfo`. To show icons, capture them with ScreenCaptureKit. To move an item, fake a ⌘-drag with synthesized `CGEvent`s.
- Needs Accessibility and Screen Recording permissions.
- Fragile: macOS updates (Sequoia, then Tahoe) have repeatedly broken how menu bar windows are reported and owned. Expect ongoing maintenance.

### 3. A secondary bar (Bartender, Ice)

- Hidden items appear in Bouncer's own panel below the menu bar instead of expanding inline. The panel draws captured images of the icons and passes clicks through to the real items.
- Solves the MacBook notch problem, where items that don't fit vanish behind the camera.
- By far the most complex option.

### Recommendation

Start with approach 1. It covers both goals: always shown means right of the divider, hidden behind a click means left of it. If ⌘-dragging feels too crude later, approach 2 can be built on top without a rewrite.

## Technology

| Concern | Choice |
|---|---|
| Language | Swift |
| Menu bar items | AppKit `NSStatusItem`. SwiftUI's `MenuBarExtra` can't change its own length, so it can't do the divider trick |
| Settings window | SwiftUI, hosted from AppKit |
| App type | Agent app (`LSUIElement = YES`), so there's no Dock icon |
| Launch at login | `SMAppService.mainApp` |
| Global hotkey | [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) package |
| Distribution | Developer ID signing, notarisation, Sparkle for updates. Approach 2 can't be sandboxed, which rules out the Mac App Store; approach 1 might pass review |

Electron, Tauri and the like aren't a good fit, because nearly all the work is native AppKit.

## Prior art

- **Hidden Bar** (MIT licence): the cleanest small example of approach 1.
- **Ice**: the most complete open-source example of approaches 2 and 3. Check its licence before copying code; it is believed to be GPL.

## Open questions for the detailed requirements

- **Notch**: on a MacBook, items that would sit behind the notch vanish. Acceptable for v1?
- **Auto-rehide**: should hidden items collapse again after a timeout, when clicking elsewhere, or only when the toggle is clicked again?
- **Native overlap**: macOS Tahoe added a setting in System Settings to turn individual apps' menu bar items on or off. Bouncer's value is the "hidden but one click away" state; make sure the two don't confuse each other.
- **Multiple displays**: does the toggle act on every display's menu bar or just the active one?
- **Is ⌘-drag enough for configuration?** That answer decides between approach 1 and approach 2.

## Naming

Chosen: **Bouncer**.

Other candidates considered:

- Bar and pub puns: Last Call, Backroom, Coaster, Barback, Tab
- Hiding and tucking away: Tuck, Stash, Cubby, Nook, Hush, Pocket
- Curtains and stage: Curtain, Wings, Backstage
- Physical dividers: Shelf, Fold, Drawer, Hinge
- Plays on Mac or menu: Menuette, Topside, Barely

Excluded as already taken: Bartender, Ice, Dozer, Vanilla, Hidden Bar.
