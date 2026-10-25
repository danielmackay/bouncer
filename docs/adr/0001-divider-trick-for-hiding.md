# Hide menu bar items with the divider trick

macOS has no public API for hiding other apps' menu bar items, so Bouncer adds an invisible Divider made of several status items and widens them until macOS runs out of menu bar room and moves everything on the Divider's left into the System Overflow. Shrinking them reveals the items again. macOS itself remembers which side of the Divider each item sits on, so Bouncer stores no item configuration and needs no permissions to hide or reveal.

The Divider is several segments rather than one wide item because macOS 27 discards any status item whose width reaches half the display, and one sub-half-width item isn't enough to fill a large display. Each segment stays just under half the narrowest display's width.

Bouncer is a personal tool targeting macOS 27 only, never distributed or sold, so it carries no compatibility code for earlier menu bars.

## Considered Options

- **Secondary bar** (Bartender style): hidden items drawn in Bouncer's own panel below the menu bar. Rejected as by far the most complex option.
- **A single huge Divider** (Hidden Bar on macOS 26 and earlier): macOS 27 drops the item entirely, so it hides nothing.
- **A single sub-half-width Divider**: hides items on a notched MacBook display but only slides them left on a 4K external display.
- **A Settings list for dragging items between sections**: on macOS 27 menu bar items aren't separate windows, so they can't be found or dragged by faking ⌘-drags. The only known route is writing an undocumented, permission-protected layout file. Rejected; the user configures by ⌘-dragging in the menu bar itself.
- **Relying on the System Overflow alone**: it only appears when items don't fit, and the user can't choose which items it takes.

## Consequences

- When Revealed on a notched display, items that don't fit still land in the System Overflow behind its « button.
- Dragging Bouncer's own Toggle into the Hidden Section would hide the Toggle too, so Bouncer has to detect and refuse that state.
- The Divider's segments are invisible, so ⌘-dragging other items can knock some out of the run next to the Divider; widened there, they would push the Shown Section into the System Overflow. Bouncer creates more segments than it needs and widens only those still in the run, refusing to Collapse when too few are left.
