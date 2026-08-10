# Master plan: jackin❯ desktop UI parity with HTML design SoT

**Mode:** planning only (this document). Implementation starts only after operator freezes this plan.  
**Planned at:** commit `f4ec1247` (`plan/desktop-visual`), 2026-08-10.  
**Product:** jackin❯ desktop — native macOS menu-bar app under `native/`.

---

## 1. Final goal (non-negotiable)

Ship a **native** status bar + glance popover + Usage window whose **look, feel, information architecture, and interaction model** match the finished HTML design reference as the **bare minimum**. Better is allowed only when it still reads as the same design system (native macOS / Liquid Glass done correctly — not a different product).

| Surface | Operator must experience… |
|---|---|
| **Status bar** | Template-mono dual-stack extras on the **system** menu bar; not glass chips; same glance % as Usage Weekly/Daily for the selected account |
| **Left-click** | Full glance popover (not a mini-pop), focused on the clicked provider, craft aligned to `popover.html` |
| **Right-click** | Enabled menu: Open Usage Window · Refresh · Quit jackin❯ desktop |
| **Usage window** | Real unified NSToolbar; floating glass sidebar; provider = identity; accounts nest with progress; detail = full Rust presentation; Open usage page; structured Limit Reset Credits |

**Success definition:** side-by-side review (HTML hub in Safari + running app on macOS Tahoe) passes the **Visual acceptance matrix** (§6). Automated gates (§7) stay green. No limits-only violations. Glass only via `GlassFallbacks`.

**Not success:** “code paths exist” while popover/Usage still look generic vs HTML; structural harness green without operator visual QA when a Mac with Xcode is available.

---

## 2. Design oracle hierarchy (how to check)

Read top-down. Later rows refine earlier ones; they do not override CONFIRMED product law.

| Priority | Source | Role |
|---|---|---|
| 1 | `plans/desktop-design-decisions.md` | CONFIRMED FB1-*, LG-A*, AR-*, VS-* product law |
| 2 | `plans/previews/desktop-ui/index.html` | **Hub craft:** system menu-bar desktop scenes, status interactions, Usage window layout |
| 3 | `plans/previews/desktop-ui/popover.html` | **Popover craft:** Overview / Providers, accounts, buckets, footer CTA |
| 4 | `plans/previews/desktop-ui/MACOS_CHROME_REFERENCES.md` | Real menu bar vs window chrome; accessory vs regular |
| 5 | `plans/previews/desktop-ui/LIQUID_GLASS_REFERENCES.md` | LG-A1–A12 map |
| 6 | `plans/previews/desktop-ui/DATA_CONTRACT.md` | Numbers/labels ↔ `jackin-usage` host APIs |
| 7 | `plans/previews/desktop-ui/OFFICIAL_USAGE_URLS.md` | Browser “Open usage page” URLs |
| 8 | `plans/previews/desktop-ui/AGENT_HANDOFF.md` | Token map CSS → Swift + agent checklist |
| 9 | `plans/previews/desktop-ui/check_usage_liquid_glass.py` | Structural invariants (must stay PASS) |

### How an implementer uses HTML as “How To Check”

1. Open `index.html` in Safari (Dark + Light). Toggle panels: **Status interactions** · **Usage window** · **Liquid Glass check**.  
2. Open `popover.html` standalone and via hub left-click embed.  
3. Build and run **JackinDesktop.app** on the same machine when possible.  
4. For each row in §6, mark **Pass / Fail / N/A (system chrome)** with a short note. Fail = remaining plan work.  
5. Re-run automated gates (§7) after every code change (**build → check → fix → build**).

**System chrome honesty:** The real menu bar (, Control Center, clock) is owned by macOS. HTML mocks it for layout education. Native **must not** draw a fake in-window system menu bar. Parity means correct *use* of NSStatusItem + activation policy, not cloning  pixels.

---

## 3. Scope

### In scope (UI parity)

- Status bar extras (`NSStatusItem` dual stack, template icons)
- Status left-click popover (shell + IA + data display craft)
- Status right-click context menu
- Usage window: toolbar, sidebar, account nest, Overview, detail, Open usage, Limit Reset Credits
- Activation accessory ↔ regular + main menu when windows open
- Tests/harnesses that lock SoT behaviors without inventing %

### Out of scope

- Capsule TUI / host console / marketing docs site  
- New providers beyond `DESKTOP_PROVIDER_ORDER`  
- Rewriting jackin-usage network/fetch pipelines  
- Token prices, spend charts, sparklines  
- Pixel-diff CI (optional later; not required for plan freeze)

---

## 4. Current foundation (already landed — do not re-plan as greenfield)

Engineering foundations through `f4ec1247` closed many **structural** gaps. Treat as **done baseline**, not “finished visual parity.”

| Area | Landed behavior (verify, don’t redo blindly) |
|---|---|
| Status focus | Left-click sets `popoverSelection` via `StatusPopoverFocus` |
| Status dual stack | `StatusItemRendering` template mono |
| Popover shell | Clear host, glass panel, soft scroll, glass footer, width ~412 |
| Popover body path | Prefers `detailPresentation` buckets; secondary account chips; Open usage |
| Usage toolbar | `NSHostingController` + `toolbarStyle = .unified` |
| Usage nest | Accounts under selection; mini meter; multi radio |
| Overview | `OverviewInventory` per-account when accounts exist |
| Detail | Mechanical rows; Limit Reset card; `ProviderUsageLinks` |
| Guards | ArchitectureLint glass/toolbar/focus; DesktopSoTParityHarness; ParityMatrix |

**Remaining work is primarily craft fidelity:** spacing, hierarchy, typography, materials, empty states, light/dark, popover sticky chrome vs HTML, account-rail inset well, detail-head density, footer CTA polish, status density, and operator-confirmed side-by-side Pass on §6.

---

## 5. Residual gap list (design-first — re-audit at plan start)

Executor must re-open HTML + native and fill this table before coding more. Severity is visual/IA, not “compiles.”

| ID | HTML / decisions reference | What “done” looks like natively | Severity if missing |
|---|---|---|---|
| G-S1 | `index.html` `.system-menubar` + `.sb-item` dual stack | Status extras: icon + compact reset top + `bar_label` bottom; template mono; no chip fill | High |
| G-S2 | Hub left-click → `popover.html?provider=` | Clicked status item focuses that provider tab/body | High (landed — re-verify) |
| G-S3 | Right-click glass menu | Three enabled actions, retained target | High (landed — re-verify) |
| G-P1 | `popover.html` sticky chrome + provider strip | Overview + providers with selection chrome matching SoT density (meters on strip optional per glance %) | High |
| G-P2 | Left account strip under provider | Secondary chips/radio; multi only; remaining % when known | High |
| G-P3 | Bucket heroes + pace + reset separation | Detail presentation layout_lines; reset trailing where Rust marks it; 0% empty meter | High |
| G-P4 | Footer glass CTA | Single Refresh dock; glass via Fallbacks; ⌘R | Med |
| G-P5 | Shell translucency | Clear NSPopover host; regular glass; soft edges | High (landed — re-verify light/dark) |
| G-P6 | Open usage / Open Usage window | Browser link + header open full Usage | Med (landed — re-verify) |
| G-U1 | Unified titlebar first line | Real NSToolbar; centered brand title; icon-only Refresh | High (landed — visual QA) |
| G-U2 | Floating glass sidebar over content | Not hard 3-pane walls; LG sidebar; soft scroll | High |
| G-U3 | Provider row identity only | Name + multi-account caption; **no** provider %/meter | High |
| G-U4 | Account nest under selected provider | Radio multi; % + mini meter; inset well polish if HTML shows well | High |
| G-U5 | Overview one row per account | Inventory titles `Provider · account`; meters 1:1 | High (logic landed — visual QA) |
| G-U6 | Detail limit-list + meta group | Single story; no dupe plan/account; Limit Reset structured | High |
| G-U7 | Open usage page | All seven surface ids | Med |
| G-A1 | Accessory vs regular | Menu bar app menus only when window key; status extras remain | Med |
| G-L1 | LG-A1–A12 | Glass nav only; content solid; no glass-on-glass | High |
| G-D1 | DATA_CONTRACT | Same fixture numbers bar ↔ sidebar trail ↔ Weekly/Daily row | High |

---

## 6. Visual acceptance matrix (operator + implementer)

Run on **macOS Tahoe** when possible. Theme: **Dark and Light**.

### 6.1 Status bar

| Check | HTML cue | Pass if |
|---|---|---|
| Dual stack | `.sb-item .t` + `.p` | Compact countdown above %; mono tabular |
| Template | `.plogo.sm` transparent | No brand color plates on bar; template glyphs |
| No glass chips | FB1-6 | No capsule fill behind status item |
| Focus | embed `provider=` | Left-click Anthropic vs OpenAI switches popover content |

### 6.2 Popover (`popover.html`)

| Check | HTML cue | Pass if |
|---|---|---|
| Size / density | ~424 craft | Feels same information density; not a sparse mini card |
| Shell | glass panel | Desktop shows through; soft shadow once |
| Tabs | Overview + providers | Selection readable; strip scroll if needed |
| Accounts | left H-scroll / rail | Secondary system ≠ provider selection |
| Buckets | heroes + pace + reset | Order matches provider template; meters empty at 0% |
| Footer | `.footer-dock` / `.cta-btn` | One glass Refresh; not solid green slab |
| Open usage | link control | Official URL opens; in-app Usage still available |

### 6.3 Usage window (`index.html` Usage panel)

| Check | HTML cue | Pass if |
|---|---|---|
| Desktop scene | `.desktop` regular menubar | App menus when window open (system); window below bar |
| Toolbar | `.chrome-float` / NSToolbar | Full-width native toolbar; icon Refresh; title brand |
| Sidebar | `.side` floating glass | Rounded glass over content; not opaque split |
| Providers | `.nav-provider` | Logo/name only; “N accounts” when multi |
| Accounts | `.acct-rail` / `.a-meter` | Nest under selection; radio multi; % + meter |
| Overview | inventory list | One card per account when multi |
| Detail | `.limit-list` / `.group` | Mechanical Rust rows; Open usage; Limit Reset detail |
| Meters | width % | 57% ≈ 57% fill; 0% = empty track |

### 6.4 Cross-cutting

| Check | Pass if |
|---|---|
| Brand | `jackin❯ desktop` spelling everywhere user-facing |
| Limits only | No prices/trends/sparklines |
| Light + Dark | Same IA; tokens from AGENT_HANDOFF map |
| Data contract | Bar 57% ⇒ Weekly “57% left” for same account |

Record results in a short `advisor-plans/VISUAL_QA_LOG.md` when implementation resumes (template in §10).

---

## 7. Automated gates (every change)

```sh
# From repo root
python3 plans/previews/desktop-ui/check_usage_liquid_glass.py
# expect: PASS: …

cd native
swift run -c release DesktopArchitectureLint
swift run -c release DesktopSoTParityHarness   # run ≥3 times if touching identity maps
swift run -c release DesktopParityMatrixHarness
swift run -c release StatusItemChipHarness
# When full Xcode present:
# swift test   # or project scheme JackinDesktop
```

**ObjectIdentifier rule:** any map test must retain NSObject instances for the assertion lifetime (see `DesktopSoTParityHarness`).

---

## 8. Implementation phases (ordered — design parity loop)

Each phase ends only when: automated gates green **and** relevant §6 checks Pass (or N/A with reason).

### Phase A — Freeze & re-baseline (no product redesign)

1. Confirm HEAD and open HTML hub + popover (dark/light).  
2. Fill residual gap table §5 with **Pass / Fail** against current app if runnable; else mark Fail as “code review only.”  
3. Update this master plan’s §4/§5 if reality drifted — do not invent new product direction.

**Exit:** Written gap table; operator agrees which Fails are in scope for next sprint.

### Phase B — Status bar & interactions (feel first)

**Oracle:** `index.html` status desktop + `MACOS_CHROME_REFERENCES.md`.

1. Dual-stack density vs HTML (font size, spacing, template).  
2. Left-click focus (re-verify G-S2).  
3. Right-click menu (G-S3).  
4. Accessory-only: no custom app menus required when no windows.

**Exit:** §6.1 all Pass.

### Phase C — Glance popover craft = `popover.html`

**Oracle:** `popover.html` end-to-end.

1. Shell translucency + soft edges + single shadow.  
2. Sticky / top chrome + provider strip selection craft.  
3. Account secondary system.  
4. Bucket presentation (detailPresentation), Limit Reset, meters 0% empty.  
5. Footer glass Refresh.  
6. Open usage page + Open Usage window.

**Exit:** §6.2 all Pass on dark + light.

### Phase D — Usage window craft = `index.html` Usage

**Oracle:** Usage panel in `index.html`.

1. Unified NSToolbar visual (title, Refresh placement).  
2. Floating glass sidebar vs content.  
3. Provider identity / account nest / meters.  
4. Overview inventory cards.  
5. Detail limit-list + meta + Open usage + Limit Reset.  
6. Regular activation + main menu presence.

**Exit:** §6.3 all Pass on dark + light.

### Phase E — Cross-cutting polish & lock

1. Token map audit (AGENT_HANDOFF) — phosphor only on selection/CTA/high metrics/j❯.  
2. DATA_CONTRACT fixture consistency.  
3. Harness extensions only for **regressions that broke §6** (no harness-only design).  
4. VISUAL_QA_LOG filled Pass across matrix.  
5. Optional: screenshots attached to PR (not required for freeze).

**Exit:** Operator signs off “HTML SoT parity achieved” for the three surfaces.

---

## 9. Engineering constraints (when implementation starts)

- Branch: stay on active feature branch (e.g. `plan/desktop-visual`); never commit `main`.  
- Conventional Commits + DCO `-s`; push after each commit.  
- Brand: **jackin❯ desktop**.  
- SwiftUI UI; `#available(macOS 26` / `glassEffect` **only** in `GlassFallbacks.swift`.  
- Never invent usage strings or %; render Rust/UniFFI only.  
- Prefer extend existing views over parallel UI stacks.  
- Extend pure helpers under `JackinUsageBridge` when logic is testable without AppKit.

### Key native paths

| Concern | Path |
|---|---|
| Status items / click | `DesktopAppDelegate.swift` (`StatusBarController`), `StatusItemLabel.swift`, `StatusItemMenu.swift` |
| Popover | `PopoverRoot.swift`, `Popover/*`, `GlassPopoverHostingController.swift` |
| Usage | `UsageWindowController.swift`, `UsageWindow/*` |
| Links / focus / inventory | `ProviderUsageLinks.swift`, `StatusPopoverFocus.swift`, `OverviewInventory.swift` |
| Store / model | `PresentationStore.swift`, `UsageWindowModel.swift` |

### Rust data (do not re-derive in Swift)

- Glance: `HostProviderGlanceRow` / `provider_glance_rows`  
- Detail: `usage_detail_presentation`  
- Accounts: `list_accounts` / `set_selected_account`  
- Order: codex, claude, amp, grok, zai, kimi, minimax  

---

## 10. VISUAL_QA_LOG template (create when implementing)

File: `advisor-plans/VISUAL_QA_LOG.md`

```markdown
# Visual QA log — jackin❯ desktop vs HTML SoT

Date: YYYY-MM-DD · App build: <commit> · macOS: <version> · Themes: Dark / Light

| ID | Check | Dark | Light | Notes |
|----|-------|------|-------|-------|
| G-S1 | … | Pass/Fail | Pass/Fail | |
…

Operator sign-off: ____________________
```

---

## 11. Related micro-plans (history)

Earlier numbered plans `001`–`005` tracked structural closure and are marked **DONE** as foundations. **This master plan supersedes them as the UI parity program of record.** Do not re-open 001–005 unless a foundation regresses.

| Plan | Role after freeze |
|---|---|
| 001–005 | Historical / foundation checklist |
| **UI_PARITY_MASTER.md (this file)** | **Active plan for look-and-feel parity** |
| VISUAL_QA_LOG.md | Filled during implementation |

---

## 12. STOP conditions (for future implementers)

Stop and report instead of improvising if:

- HTML and decisions conflict on a CONFIRMED rule — escalate to operator.  
- Rust does not supply a field HTML shows (e.g. extra Limit Reset windows) — show only Rust segments.  
- Full Xcode unavailable — finish code + harnesses; mark §6 as **blocked on operator Mac**, do not invent green visual Pass.  
- “Better than HTML” would violate FB1/LG-A (e.g. glass chips on status bar) — refuse.

---

## 13. Definition of done (program)

- [ ] §5 residual table has no High **Fail** remaining (or operator waived with reason)  
- [ ] §6 matrix Dark+Light all Pass (or N/A system chrome only)  
- [ ] §7 automated gates green on CI/local  
- [ ] VISUAL_QA_LOG operator sign-off  
- [ ] No glass outside GlassFallbacks; limits-only intact  
- [ ] DATA_CONTRACT consistency holds for fixtures used in demos  

**Until those boxes are checked under a deliberate implementation effort, the UI parity program is not finished — regardless of earlier structural commits.**
