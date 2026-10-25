# Bouncer

A macOS menu bar manager that decides which menu bar items are always visible and which stay tucked away until called for.

## Language

### Items and sections

**Menu Bar Item**:
An icon another app (or macOS) places in the right-hand side of the menu bar.
_Avoid_: Status item, icon, extra

**Shown Section**:
The Menu Bar Items that are always visible.
_Avoid_: Visible items, always-shown

**Hidden Section**:
The Menu Bar Items that stay out of sight until the user reveals them.
_Avoid_: Hidden items, overflow, stash

**Divider**:
The boundary in the menu bar between the Shown Section and the Hidden Section.
_Avoid_: Separator, spacer

**Toggle**:
Bouncer's own Menu Bar Item, which the user clicks to Reveal or Collapse the Hidden Section.
_Avoid_: Chevron, button, arrow

### States

**Revealed**:
The state in which the Hidden Section's items are visible in the menu bar.
_Avoid_: Expanded, open, shown

**Collapsed**:
The state in which the Hidden Section's items are pushed out of sight.
_Avoid_: Hidden, closed, contracted

**Auto-collapse**:
Bouncer collapsing the Hidden Section on its own after a period of being Revealed.
_Avoid_: Auto-hide, rehide

### Outside Bouncer

**System Overflow**:
macOS's own holding area for Menu Bar Items that don't fit in the menu bar, opened with its « button. Bouncer uses it to hold the Hidden Section, but doesn't control it.
_Avoid_: Overflow menu, expand button

**Disabled Item**:
A Menu Bar Item the user has turned off in macOS System Settings. It's gone from the menu bar entirely, so Bouncer can't reveal it.
_Avoid_: Removed item, always-hidden
