# Required states and evidence matrix

Status: **approved A1 requirements; no rendered evidence captured yet**

Every row is mandatory after native preview implementation. A screenshot alone
does not prove keyboard, accessibility, or restoration behavior; use the named
evidence type.

## Appearance and environment

| ID | State | Fixture/size | Required behavior | Later evidence |
|---|---|---|---|---|
| `A01` | Light, active/key | F02; popover target and window default | Native hierarchy is clear without custom material; system selection visible | Native screenshots + window metadata |
| `A02` | Dark, active/key | F02; same geometry as A01 | No washed-out text, blown-out symbols, or fixed light border | Native screenshots + pixel sanity checks |
| `A03` | Light, inactive/non-key | F02; window default | Toolbar/sidebar/selection recede through system behavior; content remains readable | Active/inactive paired capture |
| `A04` | Dark, inactive/non-key | F02; window default | Same structural recession; no child panel remains bright | Active/inactive paired capture |
| `A05` | Reduce Transparency | F02; popover and window | System substitutes supported opaque treatment; hierarchy does not depend on blur | Real setting capture + restored-setting receipt |
| `A06` | Increase Contrast | F04; popover and window | Text, separators, controls, and focus remain distinct; no color-only warning | Real setting capture + accessibility audit |
| `A07` | Reduce Motion | F07 | No custom scale/morph/spin animation; refresh state stays understandable | Interaction recording/log + restored-setting receipt |
| `A08` | Liquid Glass clear preference | F02 | System-owned surfaces remain legible at the clearer extreme | Manual native screenshot + setting receipt |
| `A09` | Liquid Glass tinted preference | F02 | Same layout/semantics at the more opaque extreme | Manual native screenshot + setting receipt |

macOS exposes no public read API for the clear/tinted preference. A08 and A09
must therefore be visually captured and operator-verified; implementation must
not branch on guessed defaults.

## Keyboard, pointer, and accessibility

| ID | State | Required behavior | Later evidence |
|---|---|---|---|
| `I01` | Keyboard focus in popover | Initial focus reaches first actionable control; Tab follows account picker → limit scroller → Refresh → Open Usage; Escape dismisses | Automated key events + focus log + screenshot with focus ring |
| `I02` | Keyboard focus in Usage | Sidebar, Overview table, account picker, detail scroller, toolbar, and links are reachable in native order | Accessibility tree + key-event test |
| `I03` | Menu commands | Command-R refreshes; Command-comma opens Settings; Command-W closes; selected Usage shortcut opens/focuses the window | Command-dispatch tests |
| `I04` | Context menu | Secondary click exposes native Open Usage, Refresh, applicable Settings, and Quit ordering | Real status-item capture + menu inspection |
| `I05` | Pointer hover/press | Native buttons, rows, status items, menus, and links own hover/press; no hover-only action | Interaction test + capture where stable |
| `I06` | VoiceOver labels | Status items name provider and glance values; controls have concise labels; decorative marks hidden; full long values exposed | Accessibility audit dump + assertions |
| `I07` | Non-color state | F04–F10 remain distinguishable through text/value/status, not only hue | Semantic assertions + monochrome/manual review |
| `I08` | Refresh announcement | F07 exposes busy/progress state without repeatedly stealing focus | Accessibility notification test/manual VoiceOver pass |

## Content and recovery

| ID | State | Fixture | Required behavior | Later evidence |
|---|---|---|---|---|
| `C01` | No providers | F00 | Fallback status item and native unavailable state; no zero meters | Popover/window capture + semantic assertions |
| `C02` | Initial loading | F13 | Native indeterminate progress; no fake content | Popover/window capture |
| `C03` | Single normal | F01 | No unnecessary provider/account navigation; full detail readable | Popover/window capture |
| `C04` | Multiple accounts | F03 | Native picker preserves Rust order and selects exhausted account correctly | Interaction test + capture |
| `C05` | Nearly exhausted | F04 | Warning is local, textual, and calm; no alert or decorative animation | Capture + hierarchy review |
| `C06` | Exhausted | F05 | 0% is valid fresh data, distinct from unavailable | Semantic test + capture |
| `C07` | Stale last-good | F06 | Values stay visible; stale/error text and Retry are local | Interaction test + capture |
| `C08` | Active refresh | F07 | Last-good data stays visible; native progress appears without layout jump | Before/during/after capture + geometry assertion |
| `C09` | Partial failure | F08 | Healthy providers stay usable; Kimi error remains local | Interaction test + Overview capture |
| `C10` | Permission denied | F09 | No fabricated account/quota; exact error and valid recovery action | Capture + text assertion |
| `C11` | Offline cached | F10 | Cached value, stale state, age, and local error remain together | Capture + text assertion |
| `C12` | Global bridge error | F14 | Native unavailable state and Retry replace domain content, not window chrome | Capture + retry test |
| `C13` | No destructive actions | F15 | No destructive control exists | Accessibility tree/menu audit |

## Sizing, scrolling, and overflow

| ID | State | Fixture/geometry | Required behavior | Later evidence |
|---|---|---|---|---|
| `S01` | Popover target | F01 at ~380 × 460 | One vertical reading path; commands visible | Real NSPopover capture |
| `S02` | Popover constrained | F12 at 320 × 280 available viewport | Metadata remains oriented; limit list scrolls; commands reachable; no horizontal carousel | Real NSPopover capture + scroll test |
| `S03` | Popover maximum | F12 at no more than 420 × 560 | Content does not grow into a phone/dashboard surface; overflow scrolls | Real NSPopover capture |
| `S04` | Usage minimum | F12 at 760 × 500 | Sidebar/detail usable; toolbar uses system overflow; no clipping/fixed child overflow | Real NSWindow capture + geometry assertions |
| `S05` | Usage default | F02 at 920 × 620 | Balanced scan density and readable detail measure | Real NSWindow capture |
| `S06` | Usage expanded | F12 at 1200 × 760 | Table benefits from width; detail does not stretch text indefinitely or invent cards | Real NSWindow capture |
| `S07` | Sidebar collapsed | F02 at 760 × 500 | Native toggle restores navigation; selection/context survives | Interaction test + capture |
| `S08` | Toolbar overflow | F11 at 760 × 500 | System overflow owns hidden items; every command remains in app menus | Capture + menu assertions |
| `S09` | Long strings | F11 at all sizes | Native wrapping/truncation is stable; full values accessible; no overlap | Captures + accessibility assertions |
| `S10` | Maximum content scroll | F12 | Keyboard and pointer can reach final row; scroll indicators/edge effect remain native | Automated scroll/focus test + capture |

## Restoration and continuity

| ID | Scenario | Required behavior | Later evidence |
|---|---|---|---|
| `R01` | Close/reopen Usage | Restore frame, sidebar width/visibility, destination, and valid account | Relaunch test with state log |
| `R02` | Restored provider removed | Fall back to Overview without stale selection or crash | Deterministic model-change test |
| `R03` | Open Usage from provider popover | Window focuses matching provider/account | Integration test |
| `R04` | Reopen popover from another status item | New clicked provider replaces previous transient context | Real status-item integration test |
| `R05` | Refresh completes/fails | Preserve selection and scroll orientation; update only source-owned state | Async integration test |
| `R06` | App activation changes | Accessory/menu-bar mode and regular Usage-window activation remain coherent | Real app lifecycle test |

## Evidence integrity

- Required popover evidence comes from a real `NSPopover` attached to a real
  status item, not an offscreen SwiftUI rendering.
- Required window evidence includes native titlebar, toolbar, traffic lights,
  sidebar, key/non-key state, and system material.
- Every blocked capture emits a failing test or explicit blocked artifact; a
  transparent placeholder cannot pass.
- Capture metadata records fixture ID, app commit, macOS build, Xcode/SDK,
  appearance, accessibility settings, window geometry, and key-window state.
- Scripts that modify macOS settings snapshot old values first and restore them
  on success, failure, and interruption.
- Rendered evidence is reviewed only after the operator selects a structure and
  explicitly confirms the runnable native preview.
