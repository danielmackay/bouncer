# Bouncer

A simple macOS menu bar manager. Bouncer decides who gets into the menu bar.

> **Status:** early design. There's no code yet; see [the brainstorming notes](docs/brainstorming.md).

## What it will do

- Keep chosen menu bar items always visible.
- Hide the rest behind a single click.
- Stay small and simple, in the spirit of Bartender and Hidden Bar.

## How it works

macOS has no public API for moving other apps' menu bar items, so Bouncer uses the divider trick. It adds a toggle and an invisible divider to the menu bar. Items you ⌘-drag to the left of the divider get pushed off-screen when it expands, and come back when you click the toggle. macOS remembers item positions itself, and no special permissions are needed.

## Planned stack

- Swift, with AppKit `NSStatusItem` for the menu bar and SwiftUI for settings
- Runs as an agent app (no Dock icon)
- Launch at login via `SMAppService`

## Licence

[MIT](LICENSE)
