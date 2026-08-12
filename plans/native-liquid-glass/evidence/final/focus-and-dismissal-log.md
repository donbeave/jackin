# Native focus and dismissal log

The host's default `AppleKeyboardUIMode` was absent. `state.sh with keyboard-navigation` temporarily set mode `3`, launched the real application, posted native Tab key events, read the focused AX element after each event, then restored the absent value. `settings-focus-before.txt`, `settings-focus-after.txt`, `settings-focus-current.txt`, and `settings-focus-final.txt` are byte-identical.

## Provider popover

Fixture F03 opened the real OpenAI popover with multiple accounts. Focus reached:

```text
0|AXPopUpButton||||secondary@example.test
1|AXGroup|||||AXScrollArea|popover.provider.codex
2|AXButton|popover.open-usage||Provider usage|
3|AXPopUpButton|popover.account-picker||Account|secondary@example.test
4|AXButton|popover.refresh||Provider usage|
8|AXButton|popover.open-usage||Provider usage|
```

The native account picker, provider limit scroller, Refresh, and Open Usage were all reachable. AppKit chose the exact cycle because Open Usage is the default action. No custom focus engine overrides system order.

After making `JackinDesktop` frontmost and posting Escape, the layer-25 popover changed from `onscreen` to `offscreen`; the dismissal check printed `popover-dismissed-by-escape`.

## Usage window

Fixture F03 opened Usage focused on OpenAI. Focus reached the native outline/content structure, its scroll bar, the fixed leading sidebar toggle, and Refresh:

```text
0|AXOutline|||||AXColumn|ListColumn
1|AXScrollBar||||
2|AXOutline|||||AXColumn|ListColumn
3|AXButton|usage.sidebar-toggle||Hide Sidebar|
4|AXButton|usage.refresh||Refresh|
```

The result uses the macOS native focus graph. Accessibility identifiers remain attached to app-owned actions; system-owned table/list descendants retain AppKit roles.
