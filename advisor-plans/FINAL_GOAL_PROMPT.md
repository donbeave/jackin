# Final `/goal` prompt — jackin❯ desktop HTML SoT UI parity

Copy everything inside the fenced block below into `/goal` (or your agent’s goal runner).  
**Do not shorten** — the agent needs the full QI contract.

Related plan docs (already in repo):

- [UI_PARITY_MASTER.md](./UI_PARITY_MASTER.md) — program of record  
- [QI_VERIFICATION.md](./QI_VERIFICATION.md) — screenshots, multimodal, build→check→fix  
- [README.md](./README.md) — index  

---

## Prompt (copy from next line through END)

```
/goal

# Mission: jackin❯ desktop — HTML design SoT UI parity (do not stop early)

You are the implementer. Your job is to make the **native** jackin❯ desktop app
(status bar · left-click popover · right-click menu · Usage window) match the
**finished HTML design SoT** in look, feel, information architecture, and
interaction model — **bare minimum = almost the same design; aim for near
pixel-perfect craft within native macOS/Liquid Glass rules**.

You MUST keep working in build→check→fix loops until you have **strong
evidence** (not hope) that parity is achieved. Harness-only green is NOT done.

---

## Program of record (read fully first)

1. `advisor-plans/UI_PARITY_MASTER.md`
2. `advisor-plans/QI_VERIFICATION.md`  ← mandatory QI / screenshot protocol
3. `plans/previews/desktop-ui/index.html` (Status + Usage panels, Dark + Light)
4. `plans/previews/desktop-ui/popover.html` (full glance popover craft)
5. `plans/previews/desktop-ui/MACOS_CHROME_REFERENCES.md`
6. `plans/previews/desktop-ui/LIQUID_GLASS_REFERENCES.md`
7. `plans/previews/desktop-ui/DATA_CONTRACT.md`
8. `plans/previews/desktop-ui/OFFICIAL_USAGE_URLS.md`
9. `plans/previews/desktop-ui/AGENT_HANDOFF.md` (token map)
10. `plans/desktop-design-decisions.md` (CONFIRMED FB1-*, LG-A*, AR-*)

HTML + decisions are the **oracle**. Never “fix” the HTML to match a worse native UI.

---

## Product law (non-negotiable)

- Brand: **jackin❯ desktop** (chevron rules in AGENTS.md / RULES.md).
- **Limits only** — no token prices, spend trends, sparklines, cost charts.
- All usage numbers/strings from **Rust/UniFFI** — Swift renders mechanically; never invent %.
- SwiftUI UI; `#available(macOS 26` / `glassEffect` **only** in
  `native/Sources/JackinDesktop/GlassFallbacks.swift`.
- Status bar: **template mono** dual stack — **never** Liquid Glass chips (FB1-6).
- System menu bar is **display chrome** — do not paint a fake /CC bar inside the app window.
- Stay on active feature branch (e.g. `plan/desktop-visual`); Conventional Commits +
  `git commit -s`; push after each commit.

---

## Scope (only these surfaces)

1. Status bar `NSStatusItem` extras  
2. Left-click glance popover (must match popover.html — not a mini-pop)  
3. Right-click context menu (Open Usage / Refresh / Quit — enabled)  
4. Usage window (NSToolbar, sidebar, account nest, Overview, detail, Open usage, Limit Reset)

Out of scope: Capsule TUI, host console, marketing docs, new providers, jackin-usage
fetch rewrites, pricing analytics.

---

## Definition of DONE (all required)

You may stop only when **all** of the following are true:

### A. Visual / QI (strongest bar)

1. For every scene in `QI_VERIFICATION.md` §5 (at least: status-desktop,
   popover-openai, popover-anthropic, usage-overview, usage-provider-nest,
   usage-detail-openai, usage-toolbar) you have:
   - HTML baseline PNG (Dark **and** Light where applicable)
   - Native capture or fixed-size SwiftUI snapshot PNG (same themes)
   - A structured **multimodal delta** file (QI §7.2 format) with **Verdict: Pass**
2. You personally **read both images** (vision / read_file on PNGs) for each
   scene and confirmed: IA, chrome roles (glass nav vs solid content), density,
   meters (1:1, 0% empty), typography hierarchy, account-vs-provider systems,
   and DATA_CONTRACT fixture numbers match.
3. `advisor-plans/VISUAL_QA_LOG.md` filled: matrix Pass (or N/A system chrome only),
   interactions Pass, no High residual gaps.
4. Near pixel-perfect means: same layout roles and proportions as HTML craft —
   not “inspired by.” System /Control Center/clock are N/A (do not clone).

If GUI/Xcode is missing: complete all code + L1/L2 gates, capture HTML baselines,
and leave L3/L4 **explicitly BLOCKED** with toolchain log — do **not** claim visual Done.

### B. Automated gates (must stay green)

```sh
python3 plans/previews/desktop-ui/check_usage_liquid_glass.py
cd native
swift run -c release DesktopArchitectureLint
swift run -c release DesktopSoTParityHarness   # run ≥3 times if touching identity maps
swift run -c release DesktopParityMatrixHarness
swift run -c release StatusItemChipHarness
```

### C. Behavior checklist

- Left-click status item focuses **that** provider in the popover.
- Right-click menu: Open Usage / Refresh / Quit enabled.
- Usage: unified NSToolbar; provider identity only; accounts nest with % + mini meter;
  Overview per-account when multi; detail = usage_detail_presentation; Open usage page;
  Limit Reset Credits structured from Rust only.
- Activation: accessory when no windows; regular when Usage/Settings open.

---

## Mandatory work method (do not skip)

Follow `QI_VERIFICATION.md` pyramid and §9 loop:

```
Open HTML → capture baseline → implement smallest Gap ID fix →
L1+L2 gates → capture native → multimodal compare (read both PNGs) →
write delta → fix until High gone → commit -s + push → next scene
```

1. **Never** implement the whole app then verify once.  
2. **Never** declare Pass on harness-only when GUI capture is possible.  
3. **Never** invert the oracle (change HTML to match bad native).  
4. Prefer fixture/frozen data (57% / 12% / 100% / multi-account a1–a2 per DATA_CONTRACT)
   for stable screenshots.  
5. Use techniques from QI §3: Playwright HTML snapshots where useful;
   `screencapture` / SwiftUI snapshot tests for native; agent vision for compare.  
6. Evidence under `advisor-plans/qi-artifacts/` (html/, native/, deltas/) and/or goal scratch;
   keep a durable trail for review.

Phases: A baseline → B status → C popover → D Usage → E lock (UI_PARITY_MASTER §8).

---

## Foundations already in tree

Structural work may already exist (StatusPopoverFocus, detailPresentation popover path,
OverviewInventory, accountMiniMeter, ProviderUsageLinks, NSToolbar host, harnesses).
**Re-verify against HTML with QI.** Do not re-open green foundations unless they fail
visual or interaction checks. Finish residual **craft fidelity** until matrix Pass.

---

## STOP conditions (report; do not invent)

- HTML vs CONFIRMED decisions conflict → stop, ask operator.  
- Rust lacks a field HTML shows → show only Rust; note in delta as data limit.  
- No full Xcode/GUI → code + L1/L2 + HTML baselines only; block L4 honestly.  
- “Better” would violate FB1/LG-A (e.g. glass status chips) → refuse.

---

## Deliverables before you stop

1. Code on active branch, pushed, DCO commits.  
2. `advisor-plans/qi-artifacts/` (or documented scratch paths) with HTML + native PNGs.  
3. Delta files with final Verdict Pass per primary scene.  
4. `advisor-plans/VISUAL_QA_LOG.md` complete.  
5. All automated gates green (logs saved).  
6. Short PR-style summary: what matched HTML, what is N/A system chrome, any waived Low items.

**You are not finished until visual evidence shows the design is the same as the HTML SoT
for status, popover, and Usage — almost pixel-perfect within native platform rules.**
Work until that clarity is strongest. Begin with Phase A (HTML baselines + gap re-audit).
```

---

END OF PROMPT
