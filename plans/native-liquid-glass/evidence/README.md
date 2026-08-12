# Runnable A1 concept evidence

`concept/` contains native window and popover captures plus JSON sidecars from
the deterministic F00–F14 fixture catalog. Sidecars record resolved window
identity, owner PID, frame size, pixel dimensions, scale, on-screen state, and
active/inactive state.

Final operator-review views:

- [Light, sidebar visible](concept/usage-brand-light-F03.png)
- [Light, sidebar collapsed](concept/usage-brand-light-collapsed-F03.png)
- [Dark, sidebar visible](concept/usage-brand-dark-F03.png)

The expanded/collapsed pair is backed by UI automation that proves exactly one
sidebar control, stable coordinates, correct Hide/Show labels, and hit testing
in both states. Capture automation samples three compositor frames and keeps the
fullest result so a transient partially rendered frame cannot become evidence.
