# jackin❯ desktop — design & product decisions

**Purpose:** Single source of truth for operator-confirmed choices from the Desktop improve / Liquid Glass / status-bar program. Planning and execution **must** read this file; when it conflicts with chat memory, **this file wins** after the last confirmed update.

**Also the contract for `/goal` and implementer agents:** this file + the HTML visual package define **what “done” looks like**. Agents do not invent look/feel; they implement and verify against these artifacts.

**Product:** jackin❯ desktop (`JackinDesktop.app`) — native macOS usage menu bar; CodexBar / OpenUsage replacement for **limits only**.

**Branch for this workstream:** `plan/desktop-visual` (update HEAD stamp when material decisions land).

**Status key**

| Status | Meaning |
|---|---|
| **CONFIRMED** | Operator agreed; implementers treat as hard requirement |
| **PROPOSED** | Advisor recommendation; **not** binding until moved to CONFIRMED |
| **OPEN** | Needs discussion; do not implement as settled |
| **REJECTED** | Explicitly out; do not reintroduce without new confirmation |

---

## 0. Source of truth for agents & `/goal` (CONFIRMED)

**Why this exists:** Operator will run implementation via `/goal` (or equivalent). The agent must produce a native app whose design matches **what was decided and shown**, not a generic macOS menu bar. Verification must be possible without re-litigating taste in chat.

### 0.1 Artifact stack (priority order)

When sources conflict, higher wins:

| Priority | Artifact | Path | Agent must |
|---|---|---|---|
| **1** | This decisions file | `plans/desktop-design-decisions.md` | Treat every **CONFIRMED** ID as a hard requirement. Do not “improve away” CONFIRMED craft. |
| **2** | HTML visual reference | `plans/previews/desktop-ui/index.html` | Match IA, hierarchy, spacing rhythm, light/dark tokens, component structure. Open in **dark and light**. |
| **3** | Agent handoff | `plans/previews/desktop-ui/AGENT_HANDOFF.md` | Follow token map, credential rules, predictability checklist. |
| **4** | Preview README | `plans/previews/desktop-ui/README.md` | Provider templates, strip rules, meter bands. |
| **5** | Future `plans/00x-*.md` | Implementation plans generated after freeze | Cite CONFIRMED IDs; steps + done criteria must map to 1–4. |
| **6** | Repo product law | `native/AGENTS.md`, `crates/jackin-usage/AGENTS.md` | Display-only Swift, limits-only, GlassFallbacks. |
| — | Chat history | — | **Not** source of truth after decisions are recorded. |

**Chat is input to this file; this file is input to agents.**

### 0.2 What HTML is (and is not)

| HTML **is** | HTML **is not** |
|---|---|
| Composed **look & feel** for status bar + popover (and later Usage window) | Copy-paste Swift / AppKit code |
| **Structure + IA** (Overview vs Providers, account left, strip centered) | Trademark-final official logo files (stand-ins until kits land) |
| **Tokenized** colors/spacing for dual theme | Pixel-perfect Liquid Glass physics |
| Acceptance **oracle** for “does the app match the design?” | Substitute for Rust data truth |

**Best practice (agent handoff research, 2025–26):** repo-local mockups + **semantic tokens** + written rules + verification gates beat free-form “make it Apple.” HTML alone → generic UI; tokens alone → no composition. **We ship composition + tokens + rules.**

### 0.3 Predictable agent output (required practices)

Implementer agents **must**:

1. **Read stack 1→4 before coding.**  
2. Produce a **token map** (CSS custom property → Swift `Color` / font / spacing constant) in the plan or PR.  
3. Implement **screen-by-screen** in order: status bar → Overview → Providers detail → (later) Usage window.  
4. Use **only** named tokens for color/spacing; no free hex inventing.  
5. Keep **meters** on 3 status levels only; brand color **only** on logo plates.  
6. Show **credential source** as exact Rust `credential_origin` only.  
7. Keep **reset** on its own line (not mixed with pace/used).  
8. Verify **dark + light** (or document Reduce Transparency fallback).  
9. After UI lands: **compare** native screenshots to HTML (human and/or vision). Mismatch = not done.  
10. Cite **CONFIRMED IDs** (e.g. SB-17, FB1-31) in PR/plan done criteria.

Implementer agents **must not**:

1. Treat “Apple HIG” as license to ignore HTML layout.  
2. Invent multi-provider rainbow meters.  
3. Add in-app “how jackin resolved credentials” prose.  
4. Redesign product IA without operator confirmation.  
5. Skip the visual package because “SwiftUI has defaults.”

### 0.4 `/goal` verification package (acceptance)

When the operator runs `/goal` against this workstream, **done** means all of:

| Gate | How to verify |
|---|---|
| Product law | Limits-only; display-only Swift; frozen catalog |
| Decisions | Every **CONFIRMED** requirement in this file for in-scope surfaces is met or explicitly deferred |
| Visual | Native UI matches `index.html` for status bar + popover (dark + light) within craft tolerance |
| Tokens | Colors/spacing from shared map, not ad hoc |
| Auth UI | Credential source = Rust string only |
| Bar | Transparent dual-stack; ≤3; weekly-first rank; hide 0% |
| Popover IA | Overview inventory; Providers strip + full templates; accounts left; providers centered |
| Tests | Existing desktop harnesses + new tests for rank/selection as planned |

**Operator check:** “Does this look like the HTML reference I approved?” If no → not accepted.

### 0.5 Package paths (always keep in sync)

```text
plans/desktop-design-decisions.md          ← this file (product + craft law)
plans/previews/desktop-ui/index.html       ← hub: status flow + Usage window + Liquid Glass check
plans/previews/desktop-ui/popover.html     ← full popover reference (all providers)
plans/previews/desktop-ui/AGENT_HANDOFF.md ← agent procedure + token map
plans/previews/desktop-ui/README.md        ← short operator/agent index
plans/README.md                            ← index of plan artifacts
```

Any material design change: update **HTML + this file** in the same PR. HTML without a decision ID is not CONFIRMED.

### 0.6 Liquid Glass re-verify (CONFIRMED 2026-08-10)

Apple: glass is the **navigation/control layer**; content stays standard materials.

| Surface | Material | Consistent with Tahoe? |
|---|---|---|
| Menu bar status items | Transparent / template (no chip chrome) | Yes |
| Right-click context menu | Glass menu | Yes |
| Glance popover shell | Glass | Yes |
| Popover content cards | Solid / inset | Yes |
| Usage sidebar + toolbar | Glass | Yes |
| Usage detail pane | Solid content | Yes |
| Meters / text / buckets | Content layer | Yes — no glass on data |

**jackin accent** only on selection, CTA, high status, monogram — does not recolor system glass.

---

## 1. Decision process (CONFIRMED)

How we lock choices:

1. **Discuss** in conversation (concepts, research, tradeoffs).
2. **Propose** clear options in this file under **PROPOSED** or **OPEN**.
3. **Operator confirms** in chat (explicit: “confirm”, “agreed”, “do X”).
4. **Record** here: move to **CONFIRMED**, set date, short rationale, link to topic section.
5. **Planning gate (CONFIRMED 2026-08-10):** **no implementation plans** and **no improve-skill plan generation** until the freeze sequence below completes. Until then: **collect vision only** — discuss, confirm, update this file.
6. **Freeze sequence (CONFIRMED 2026-08-10)** — required order:
   1. Operator continues explaining vision / confirming pieces into this file.
   2. Operator declares readiness, e.g. **“I explained everything. Do you have any questions?”** (or equivalent).
   3. Advisor runs a **full grill**: every OPEN/PROPOSED/vague item, edge case, and contradiction — until no material questions remain (or remaining items are explicitly deferred with CONFIRMED “out of scope for this plan”).
   4. Operator answers; advisor updates this file to **CONFIRMED** / **REJECTED** / deferred.
   5. Operator freezes with e.g. **“decisions complete”** / **“generate plan from decisions file.”**
   6. **Then** improve skill: point at this file and produce proper implementation plan(s). Not before.
7. **Planning** (when allowed) only treats **CONFIRMED** as requirements. No silent PROPOSED defaults in executable plans unless operator confirmed them in the grill.
8. **Change control:** to reverse a CONFIRMED item, operator says so explicitly; mark **superseded** with date — never silent rewrite.
9. **Correctness over ROI:** do not leave known-wrong state because of cost/effort. Stop only if **proven** impossible (tool/platform/legal). See §2.

**Who updates this file:** the advisor/agent session that receives the confirmation, in the same turn when practical.

**Related planning:** future `plans/00x-*.md` files must cite sections of this document (e.g. “per §4.1 CONFIRMED”).

---

## 2. Engineering philosophy (CONFIRMED)

From operator direction (2026-08-10):

| Rule | Detail |
|---|---|
| **Latest-only / forward** | Prefer modern APIs and ambitious target UI. No backward-compat shims as a design goal (aligns with repo pre-release + latest-only rules). |
| **Ambitious target** | High-class native Liquid Glass craft; not incremental polish of a wrong scaffold. Huge refactors OK when the goal requires them. |
| **No ROI gate** | Judge by correctness, consistency, goal fit — never “low value / not worth it / edge case” to leave wrong state. |
| **Competitor wrong ≠ OK** | CodexBar/OpenUsage mistakes are **gaps**, not permission to ship the same wrong. |
| **Bugs = architecture** | Before fixing, name the class of failure the structure allowed; prefer structural fixes over symptom guards. |
| **Display-only Swift** | Unchanged product law: Rust owns probes, ranking strings, numbers; Swift paints only. |
| **Limits only** | No token unit prices, historical spend trends, sparklines, cost donuts, buy-credits UX. Quota limits, remaining/used %, resets, plan/status, multi-account only. |

---

## 3. Product scope (CONFIRMED + OPEN)

### 3.1 CONFIRMED — what Desktop is for this program

- Native **macOS menu-bar** app (LSUIElement), glance popover, Usage window.
- **Frozen host catalog** only: Claude, Codex, Amp, Grok, Z.AI/GLM, Kimi, MiniMax (OpenCode per existing Desktop icon domain rules).
- **Limits-only** usage surface (see §2).
- Near-term focus: **status bar as burn-first command surface** + **official provider identity marks** — before Agent Hub (daemon, PR inbox, Ghostty).

### 3.2 OPEN — later product (not this decision cycle)

- Full Desktop Agent Hub (daemon, workspaces, GitHub PR inbox).
- Production notarization / Homebrew cask (ops track; parallel, not design substitute).

---

## 4. Status bar — “burn first” (partially confirmed)

### 4.1 CONFIRMED — goals

| ID | Decision |
|---|---|
| SB-1 | Status bar must answer: **where should I burn quota first** so tokens/limits are not wasted. |
| SB-2 | Priority signal is **agents with usage that will soon expire** (use-it-or-lose-it intent). |
| SB-3 | Show **at most three** agents on the bar for this focus UI (**1, 2, or 3** — never more than three). |
| SB-4 | Presentation must be **compact** (menu bar space is scarce). |
| SB-5 | **Color** indicates which providers to focus on first (urgency / priority). |
| SB-6 | **Provider logo is critical** — real, official, recognizable marks on the status bar (with color as indicator), not generic SF Symbols as primary identity. |

### 4.1a CONFIRMED — dual-line chip + ranking (2026-08-10)

Operator confirmed the **menu-bar meter pattern** (like download apps: two stacked lines, e.g. down/up speed): two numbers that stay **simple and scannable**.

| ID | Decision |
|---|---|
| SB-7 | Each status chip shows **two lines of numbers** next to the official logo (not logo-only, not single-line only). |
| SB-8 | **One line = remaining quota to burn** — **percentage left** (how much is left / how much we can still use). Prefer **remaining %**, not “% used,” for this surface unless later confirmed otherwise. |
| SB-9 | **Other line = time until that window expires/resets** — how long we have to burn it. |
| SB-10 | **Time unit preference: hours first**, with a fixed ladder — see **SB-18**. |
| SB-11 | Numbers must be **immediately understandable**: (1) how much time we have, (2) how much we need to burn / how much is left. That pair is the priority payload of the bar. |
| SB-12 | **Ranking = waste-first / burn-first:** prefer the provider that is **top of the “will waste if I don’t use it” list** — highest **unused remaining** competing with **lowest (soonest) time left**. Operator wording: rank by who is **top unused** with the **lowest possible time** to act; bar order **updates** so the **top rank is always the first thing you see**. |
| SB-13 | **Bar order is dynamic:** left (or first chip) = **rank 1** (burn now); then rank 2, rank 3. As clocks and remaining change, **who appears and in which order** updates immediately so the operator can track priority from a glance at the top. |
| SB-14 | Hard cap remains **≤ 3** chips (SB-3). |
| SB-17 | **Rank formula (CONFIRMED):** **soonest-then-remaining** — among eligible agents, sort by **soonest reset / shortest time left first**; **tie-break by higher remaining %** (more unused headroom to waste ranks above equal-time peers). Not scarcity-only (lowest % first). Not a free-form score unless later superseded. |
| SB-18 | **Time display ladder (CONFIRMED, 48h breakpoint):**  
  - **&lt; 1 hour** → compact minutes (e.g. `45m`)  
  - **&lt; 48 hours** → compact **hours** (e.g. `14h`; may include `14h 30m` only if space allows — default whole hours OK)  
  - **≥ 48 hours** → compact **days** (e.g. `3d`; optional `3d 4h` if space)  
  Prefer hours until the 48h line; do not show a raw multi-day hour count (e.g. not `72h`). |
| SB-19 | **Hide 0% (CONFIRMED):** agents with **remaining 0%** (nothing left to burn) **do not appear** on the burn-first status bar — no icon, no chip, out of ranking. They may still appear in the full popover / Usage window. |
| SB-20 | **Driving quota window = Weekly-first (CONFIRMED):** the status-bar chip’s **% left** and **time left** (and rank inputs) use the provider’s **Weekly** window when it exists. **Not** Session / “current session.” Session is **not** a status-bar problem and must **not** drive the bar. |
| SB-21 | **No-weekly providers (CONFIRMED):** if a provider has **no Weekly** window (e.g. **Amp Free Daily**), use that provider’s **existing primary non-session glance window** (Amp: Daily). Do not invent a weekly line; do not fall back to Session for the bar. |
| SB-22 | **Status bar vs popover (CONFIRMED):** bar = burn-first compact chips only (logo + time + weekly-or-fallback %). **Popover** (and Usage window) = full detail for a **specific provider and account** (session buckets, dual windows, multi-account, errors, 0% rows, etc.). Operator sees deep detail there, not on the bar. |

### 4.1b CONFIRMED — open path: bar chip → focused popover (2026-08-10)

Bar shows **at most three** provider chips. Click is the main path into detail for **that** chip’s data — not a generic Overview open.

| ID | Decision |
|---|---|
| SB-23 | **Left-click a status-bar chip** opens the **existing glance popover**, anchored on that chip, **immediately focused** on the **same provider** represented by that chip (not Overview, not a random/other tab). |
| SB-24 | **Provider tab selection:** popover tab strip (Overview + providers) must land with that **provider selected** so the operator sees that provider’s body at once. |
| SB-25 | **Account selection:** the popover must show the **same account** whose weekly-or-fallback (SB-20/21) numbers are on that status chip — the account used for bar rank/display (Rust-selected / “most unused for waste-first” identity for that surface). If the provider has multiple accounts, that account is **selected** in the account chips so detail matches the bar. |
| SB-26 | **Immediate detail:** on open, operator sees full popover content for that provider + account (buckets, resets, plan, multi-window detail allowed here — SB-22) without a second click to pick provider or account. |
| SB-27 | **Popover height — bigger vertically (CONFIRMED):** use **more vertical space** so primary content fits. Prefer a **taller popover** over forcing the operator to scroll. |
| SB-28 | **Minimize / avoid internal scrolling (CONFIRMED):** do **not** treat the popover body as a small viewport that must scroll for normal detail. Layout so content is **visible without scrolling** as much as possible (grow height; reduce wasted chrome). Scrolling is a last resort for extreme edge cases (e.g. pathological multi-account + many windows), not the default experience. |

**Architecture class (known bug → required fix):** today left-click may open the popover **without** binding `popoverSelection` (and account) to the clicked surface — anonymous button. **Structural requirement:** every status chip owns **surface id + account key** (or Rust slot identity); open always applies that selection to the store before show.

**Visual intent (CONFIRMED shape, not pixel-final):**

```text
  [LOGO]  14h      ← time left (hours-first compact; escalate when long)
          67%      ← remaining % left (how much to burn / left)
```

(Exact which line is top vs bottom: operator said **bottom = how much is left (%)**, **other line = hours left** → **time on top, % on bottom** unless later revised.)

| ID | Decision |
|---|---|
| SB-15 | **Top numeric line:** time remaining until reset/expiry (hours-first per SB-10). |
| SB-16 | **Bottom numeric line:** **percentage remaining** (left). |

**Analogy locked:** dual readout like download UI (two concurrent metrics), not a single merged string if two lines fit the chip.

### 4.1c CONFIRMED — Overview tab (popover) redesign (2026-08-10)

Overview is a **simple inventory**, not a second full detail page. Operator rejects current Overview look/feel as **ugly, unreadable, cheap** (tiny type, unclear chrome, wrong metrics). Redesign is a **primary popover goal**.

| ID | Decision |
|---|---|
| OV-1 | Overview is **simple** — not session-detailed; **not** a dump of every bucket. |
| OV-2 | **Weekly-first** (same window rules as bar: **SB-20/21**). **No Session** content on Overview. |
| OV-3 | Structure: **one block per provider** (all relevant providers, not only the bar’s top 3). |
| OV-4 | **Multi-account:** if a provider has multiple accounts, **list each account** on Overview — critical. |
| OV-5 | Per account (or single account), show at least: **remaining % left** (weekly/fallback) + **reset** as **relative** (“resets in N days/hours…”) **and** a clear **reset date** (calendar-style when known). |
| OV-6 | **Progress / capacity bar per account**, not one bar for the whole provider when multi-account. One account → one bar. |
| OV-7 | **Fully used (0% left) accounts still appear on Overview** with explicit “fully used / nothing left” treatment. **Different from status bar (SB-19):** bar hides 0%; Overview **must show** depleted accounts so the operator still sees them. |
| OV-8 | **Per-account refresh control:** near each account row, a clear **refresh button/icon** that **force-refreshes that account** (or that provider+account) immediately. |
| OV-9 | **No global Refresh footer** on the popover for now — remove the bottom global Refresh row and **⌘R hint**. Global refresh “doesn’t make sense” for this vision; per-account refresh is the control. |
| OV-10 | **Remove unclear chrome:** e.g. unexplained **blue/severity dots** (or similar) that the operator cannot interpret — no mystery glyphs. Identity via **official logos** + clear labels. |
| OV-11 | **Remove Overview-level progress** that is not tied to an account (e.g. a single “loading bar” under the whole Overview that doesn’t map to weekly/account). |
| OV-12 | **Look & feel is a hard product requirement**, not polish: current Overview and provider list rows are **rejected** as poor hierarchy (too-small type, weak structure, unintuitive). Redesign must follow **high-quality native density practices** (see OV-13). |
| OV-13 | **Design-system direction for Overview (CONFIRMED intent; pixel specs later):**  
  - Clear **visual hierarchy** (provider name strongest; % and reset secondary; meta quieter)  
  - **Larger, readable type** for primary numbers (not caption2-everything)  
  - **System fonts** (SF Pro) with **weight/size** steps, not one tiny size for all  
  - **Semantic color** for state (healthy / warn / depleted / error) — not decoration  
  - **Generous padding** and consistent spacing (8pt-scale), aligned columns  
  - **Grouped provider cards** with account rows inside; breathing room  
  - **Official logo** as identity mark  
  - Concentric continuous corners; glass chrome only on control layer (VS-1)  
  - Tap/click targets large enough for refresh controls  
  Align with Apple HIG: **Clarity / hierarchy via layout**, not clutter. |

**Information architecture (CONFIRMED shape):**

```text
Overview
  ┌ Provider (logo + name) ─────────────────────────┐
  │  Account A   67% left   Resets in 3d · 15 Aug   ↻ │
  │  ████████░░░░  (meter for A)                      │
  │  Account B    0% left   Fully used · resets …   ↻ │
  │  ░░░░░░░░░░░░  (meter empty / depleted)           │
  └───────────────────────────────────────────────────┘
  ┌ Provider …                                          │
```

Provider **detail tabs** (non-Overview) still carry deeper fields (session, multi-window, etc.) per SB-22 — Overview stays the **simple weekly-or-fallback + accounts** surface.

### 4.1d REJECTED — current Overview / popover chrome

| ID | Rejected |
|---|---|
| OV-R1 | Session-heavy Overview rows |
| OV-R2 | One progress bar for multi-account provider |
| OV-R3 | Hiding 0% accounts from Overview (bar rule does **not** apply here) |
| OV-R4 | Global Refresh footer + ⌘R caption on popover |
| OV-R5 | Unexplained status/severity dots as primary chrome |
| OV-R6 | Tiny uniform caption typography / cramped “cheap” layout as shipping design |

### 4.1e CONFIRMED — Usage window: data OK, presentation rejected (2026-08-10)

The **Usage window** (full window: overview sidebar + provider detail / Capsule-parity rows) is in scope for craft, not only the popover.

| ID | Decision |
|---|---|
| UW-1 | **Information content is correct and wanted** — what the window shows (fields, ordering, limits-only detail) is **right**; do **not** invent a different data model or strip useful rows for “minimalism.” |
| UW-2 | **Visual presentation is rejected** — current Usage window looks **cheap, unprofessional, low quality**: type too small / hard to read, weak hierarchy, poor padding, weak color use, overall **ugly and unclear**. Redesign representation only. |
| UW-3 | **Same craft bar as Overview (OV-12/OV-13):** high-quality native hierarchy — readable primary numbers, larger type where it matters, consistent spacing (8pt-scale), semantic color for state, clear grouping (cards/sections), official logos, breathing room. Not caption2-everything lists. |
| UW-4 | **Reorganize layout for scanability** — same data, better structure (sections, alignment, label/value rhythm, meter placement) so the window feels intentional and high-class, not a raw field dump. |
| UW-5 | **Discoverability of opening the Usage window is weak (CONFIRMED problem):** how to get from bar/popover into this detailed window is **not intuitive**. Must design a **clear, obvious path** (affordance + label) — not rely on hidden header-click folklore alone. Exact control placement OPEN until grill (UW-O1). |

**Principle locked for all Desktop surfaces (bar / Overview / provider popover tab / Usage window):**

```text
Data truth (Rust)     = keep / correct
Visual presentation   = redesign to premium native quality
```

### 4.1f OPEN — open-path UX (grill later)

| ID | Question |
|---|---|
| UW-O1 | **Primary control to open Usage window:** e.g. explicit button in popover (“Open Usage…” / “Details…”), toolbar in popover, double-click provider, keep + label header click, right-click menu only, or combination? |
| UW-O2 | Should Usage window open **pre-focused** on the same provider+account as the popover (mirror SB-23–26)? **Lean yes** — confirm in grill. |
| UW-O3 | Provider **detail tab** inside popover: same redesign pass as Overview, or Usage window is the only “full detail” surface and popover provider tab stays lighter? |

### 4.2 PROPOSED — still awaiting confirmation

| ID | Proposal | Notes |
|---|---|---|
| SB-P1 | **Ranking owned by Rust** (urgency slots max 3); Swift only renders. | Aligns with display-only; should CONFIRM |
| SB-P4 | **Color on chip chrome** (rim/fill) for rank/severity; logo stays template official mark | |
| SB-P5 | ~~Left-click chip → glance focused on that provider~~ | **Superseded by CONFIRMED SB-23–SB-26** |
| SB-P6 | Popover = **full** inventory; bar = top urgency ≤3 only | Still open only as “Overview always available in strip” — bar still ≤3 |

### 4.3 OPEN — still need decisions

| ID | Question | Notes |
|---|---|---|
| SB-O4 | **Needs-login / error** | Steal a bar slot or **popover only**? (Lean: popover only — bar is burn ranking.) |
| SB-O5 | **No eligible agents** (all 0% / no weekly-or-fallback with remaining &gt; 0) | jackin fallback only / empty? |
| SB-O6 | Bar **always remaining %** even if Settings later allows “% used” elsewhere? | Intent SB-8: remaining left on bar — confirm hard-lock. |
| SB-O9 | Eligible only if **known reset time** + remaining &gt; 0 on driving window? | Remaining &gt; 0 but **no** `resets_at` — include (time `—`?) or exclude from burn bar? |

### 4.4 REJECTED (for this bar)

| ID | Rejected | Why |
|---|---|---|
| SB-R1 | Logo-only chips with no numbers | Operator needs % + time readable at a glance |
| SB-R2 | Single-line only (`67%` or `2h` alone) as the full chip payload | Dual-line confirmed (SB-7–SB-11) |
| SB-R3 | Rank by scarcity alone (lowest % first, ignore reset clock) | Conflicts with waste-first / soon-expire + high unused (SB-12); superseded by **SB-17 soonest-then-remaining** |
| SB-R4 | Show **0%** agents on the burn-first bar | Nothing left to burn — **SB-19 hide 0%** |
| SB-R5 | Display multi-day windows as raw hours (e.g. `72h`) | **SB-18** uses days at ≥ 48h |
| SB-R6 | Status bar driven by **Session** / current-session window | **SB-20** Weekly-first; session detail lives in **popover** (**SB-22**) |
| SB-R7 | Dual % lines on bar for Session + Weekly | Bar uses **one** driving window only (**SB-20/21**); session stays popover |
| SB-R8 | Open popover on Overview (or unselected) when clicking a bar chip | Must open on **that provider + account** (**SB-23–SB-26**) |
| SB-R9 | Default small popover with heavy **ScrollView** as the normal layout | Prefer **taller** popover, **little/no** body scroll (**SB-27–SB-28**) |

---

## 5. Provider logos & identity (partially confirmed)

### 5.1 CONFIRMED — requirements

| ID | Decision |
|---|---|
| LG-1 | Logos must be **real official** brand marks — **recognizable** as OpenAI, Anthropic, Amp, xAI, Kimi, etc. |
| LG-2 | SF Symbols (or invented monograms) are **not** acceptable as the primary provider identity when official art exists. |
| LG-3 | Same identity system should serve **status bar**, and (intended) **popover + Usage window** once wired — one mark family. |
| LG-4 | Acquisition prefers **first-party brand / press kits**; not random logo CDNs as source of truth. |
| LG-5 | **Display names = real provider / company names (CONFIRMED 2026-08-10)** — UI should lead with **OpenAI**, **Anthropic**, **Amp**, **xAI**, etc., not only product codenames as the primary label. Product names (Codex, Claude, Grok Build…) may appear as secondary/subtitle where useful, but **provider name is critical and primary**. |
| LG-6 | **Per-provider brand color (CONFIRMED intent)** — each provider has a **distinct color** used with its logo/chrome (mark plate, meter accent, selection tint) so identity is instant. Exact hex palette OPEN until operator picks from previews. |
| LG-7 | **Decision process: one-by-one (CONFIRMED)** — advisor presents **one decision** + preview; operator says what they **like / don’t like**; file updates; then next decision. No batch freezes until operator is ready. |

### 5.1b Provider display map (intent — refine in one-by-one)

| Surface id (Rust) | Primary UI name (target) | Product (secondary) |
|---|---|---|
| `codex` | **OpenAI** | Codex |
| `claude` | **Anthropic** | Claude |
| `amp` | **Amp** | Amp |
| `grok` | **xAI** | Grok |
| `kimi` | **Kimi** / Moonshot | Kimi Code |
| `zai` | **Z.ai** | GLM |
| `minimax` | **MiniMax** | — |

### 5.2 PROPOSED — native macOS format (research-backed; awaiting confirmation)

| ID | Proposal |
|---|---|
| LG-P1 | **Ship format:** single-page **PDF (vector)** per provider, ~**16 pt** optical size, artboard ≤ **22 pt** height. |
| LG-P2 | **Status bar render:** `NSImage.isTemplate = true` (black silhouette / alpha; system tints for light/dark/wallpaper menu bar). |
| LG-P3 | **Urgency color** on **chip chrome only**; do not recolor marks when brand rules forbid (e.g. OpenAI Blossom). |
| LG-P4 | **Masters:** keep official SVG/PDF/PNG from brand ZIPs; convert to template PDF for the app. |
| LG-P5 | **Not** for provider marks: macOS 26 Dock `.icon` / Icon Composer (app icon only). |
| LG-P6 | Repo path (when landed): `native/Sources/JackinDesktop/Resources/ProviderMarks/` + `PROVENANCE.md` (URL, date, terms). |

### 5.3 Official download map (research; update when packs land)

| Surface id | Brand mark | Official source | Ship as | Kit status |
|---|---|---|---|---|
| `codex` | OpenAI **Blossom** | [openai.com/brand](https://openai.com/brand/) | `codex.pdf` template | Official path known |
| `claude` | Claude **spark / starburst** | Anthropic / Claude media or press kit (request if no public ZIP) | `claude.pdf` template | **Gap** — need kit |
| `amp` | Amp logomark | [ampcode.com/press-kit](https://ampcode.com/press-kit) | `amp.pdf` template | Press kit |
| `grok` | Grok / xAI mark | [x.ai/legal/brand-guidelines](https://x.ai/legal/brand-guidelines) → Download Logos | `grok.pdf` template | Official path known |
| `kimi` | **KIMI icon** (not full wordmark) | [KIMI Brand Guidelines](https://moonshotai.github.io/Branding-Guide/) | `kimi.pdf` template | Public downloads |
| `zai` | Z.ai mark | [z.ai](https://z.ai/) assets or brand request | `zai.pdf` template | **Gap** |
| `minimax` | MiniMax mark | [MiniMax_Logo.zip](https://file.cdn.minimax.io/public/MiniMax_Logo.zip) (docs brand section) | `minimax.pdf` template | Official ZIP |
| fallback | jackin❯ | Existing `JackinMark.pdf` | keep | Done |

### 5.4 OPEN — logos

| ID | Question |
|---|---|
| LG-O1 | Confirm **PDF + template** as only status-bar ship format? |
| LG-O2 | Full-color “original” marks in popover/window, or template mono everywhere? |
| LG-O3 | If Claude/Z.AI pack missing: **block** surface icon until official file exists vs temporary exception? |
| LG-O4 | Operator supplies downloaded ZIPs vs agent fetches only from documented URLs? |
| LG-O5 | Trademark / referential-use legal OK for multi-agent usage bar? (operator/legal call) |

---

## 6. Liquid Glass & visual system

**Canonical Apple sources (implementation + craft law):**

| Doc | URL |
|---|---|
| Liquid Glass (Technology Overviews) | https://developer.apple.com/documentation/technologyoverviews/liquid-glass |
| Adopting Liquid Glass | https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass |
| SwiftUI (Technology Overviews) | https://developer.apple.com/documentation/technologyoverviews/swiftui |
| Applying Liquid Glass to custom views (SwiftUI) | https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views |
| HIG Materials | https://developer.apple.com/design/human-interface-guidelines/materials |

**Native UI stack (CONFIRMED):** jackin❯ desktop ships **SwiftUI only** for new/changed surfaces (see Apple *SwiftUI* technology overview). Liquid Glass / materials go through **`GlassFallbacks.swift` only** (`glassEffect`, `#available(macOS 26)`). No freestyle UIKit glass, no second material helper.

| ID | Status | Note |
|---|---|---|
| VS-1 | **CONFIRMED** | Liquid Glass on **navigation/control chrome only**; content cards standard materials (Apple *Adopting Liquid Glass* + HIG Materials + `GlassFallbacks`). |
| VS-2 | **CONFIRMED** | One visual system owns radii/glass/meters; all surfaces compose through it (no freestyle panels). |
| VS-3 | OPEN | Full award-craft glance/window rebuild scope and phasing (after status bar decisions). |
| VS-4 | OPEN | Motion / morph language requirements. |

### 6.0 Apple Liquid Glass principles → jackin❯ desktop (CONFIRMED 2026-08-10)

Mapped from Apple *Liquid Glass*, *Adopting Liquid Glass*, HIG *Materials*, and SwiftUI Liquid Glass APIs. HTML previews approximate these; native implements them via SwiftUI + `GlassFallbacks`.

| ID | Apple principle | jackin❯ application |
|---|---|---|
| **LG-A1** | LG is the **topmost functional layer** for navigation (sidebars, toolbars, tab bars, menus, popovers) floating above content | Status **context menu**, glance **popover shell**, Usage **sidebar + toolbar/titlebar**, popover **footer CTA** = glass. Status **menu bar items** stay transparent/template (FB1-6) — not glass chips. |
| **LG-A2** | **Do not use Liquid Glass in the content layer** | Usage detail, Overview inventory, limit rows, provider cards, meters, credential text = **standard materials / solid fills** (`GlassFallbacks.contentCardBackground`, `windowContentBackground`). Never glass the data list itself. |
| **LG-A3** | **Clear navigation hierarchy** distinct from content | Usage = `NavigationSplitView` (sidebar nav vs detail content). Popover = sticky chrome (brand + Overview/Providers) vs scrollable content. |
| **LG-A4** | **Use LG sparingly** on custom views; system components pick it up first | Prefer SwiftUI `NavigationSplitView`, `.toolbar`, `List`/sidebar style. Custom glass only via `GlassFallbacks` for popover panel, sidebar bg, toolbar capsules, footer dock — not every control. |
| **LG-A5** | **Avoid stacking glass on glass** | One glass chrome layer; content under it. No nested glass cards inside glass sidebar. Account rail is soft inset, not a second `glassEffect`. |
| **LG-A6** | Sidebars/toolbars **float** and refract ambient content / environment | Usage sidebar glass over solid content; HTML: transparent shell + stage bleed. Prefer content that can extend under sidebar edge (edge-to-edge) when implementing SwiftUI. |
| **LG-A7** | **Scroll edge effects** keep controls legible as content moves under chrome | Soft dissolve under popover chrome/footer and under Usage titlebar (`scrollEdgeEffect` / HTML mask fades). Soft default; hard only when pinned accessories need it (macOS). |
| **LG-A8** | **Toolbar grouping** — group related actions | Usage toolbar: single primary **Refresh** group (not scattered). Popover: one CTA dock, not multiple competing glass CTAs. |
| **LG-A9** | Tint **selectively** for functional purpose | Phosphor (`#5CF07A` / light `#0B774E`) only on selection, primary CTA, high-status metrics, j❯ — not full green glass surfaces. |
| **LG-A10** | **Regular** glass variant for dense text / popovers when legibility matters | Glance popover + menus use regular-style glass proxy; reduce transparency → ultraThinMaterial in `GlassFallbacks`. |
| **LG-A11** | Build with latest Xcode / macOS 26 SDK for automatic system chrome | Release builds use macOS 26 SDK so Tahoe LG resolves; deploy target may stay lower with fallbacks (repo `native/README.md`). |
| **LG-A12** | **SwiftUI is the UI framework** for Liquid Glass adoption docs | Desktop windows/popover chrome authored in **SwiftUI**; UniFFI bridge for data; no parallel UIKit redesign path for Usage/glance. |

**Reject (Apple + product law):** glass on limit tables; glass stacked on glass; multi-provider rainbow glass fills; inventing % in Swift; token prices / spend trends.

### 6.1 CONFIRMED — representation principles (2026-08-10)

Operator: too much on **one line** → cluttered/ugly. Data correct; packing wrong. Must feel closer to **real Apple apps**.

| ID | Decision |
|---|---|
| VS-5 | **No one-line field dumps** — do not put many independent facts on a single horizontal row. Prefer **stacked** label → value (and meter) with air. |
| VS-6 | **Space is a feature** — use Apple-like negative space / 8pt rhythm; less is not “less data,” it is **clearer structure**. |
| VS-7 | **Apple-native craft target** — hierarchy via size/weight/color (SF Pro), grouped lists/cards, semantic system colors, concentric radii; not generic dense “admin table” UI. |
| VS-8 | **Concept selection via previews** — operator picks among visual concepts (HTML first) before implementation plans freeze layout. |
| VS-9 | **One consistent design system everywhere (CONFIRMED)** — status bar, Overview, provider popover tab, Usage window, menus: **same** type scale, spacing rhythm, meter anatomy, severity colors, account-row pattern, logo treatment, and importance hierarchy. No one-off “this screen looks different” designs. |
| VS-10 | **Luxury / high-quality bar (CONFIRMED)** — ship quality as if **Apple designers/engineers** built a native macOS usage surface: calm, refined, informative, scannable. Explicitly reject cheap/crowded look. |
| VS-11 | **Importance hierarchy (CONFIRMED)** — always encode **important vs less important**: **Primary** = remaining % left, time to reset, which provider/account. **Secondary** = plan, pace, run-out. **Tertiary** = auth origin, updated, debug-ish meta. Size, weight, and color carry that order. |
| VS-12 | **Native macOS first (CONFIRMED)** — craft question: *“What if Apple designed jackin❯ desktop?”* Use **latest Apple language** (Tahoe / Liquid Glass: glass for navigation/control, content solid & legible, concentric corners, SF Pro, system semantics). |
| VS-13 | **jackin❯ brand blended with Apple, not fighting it (CONFIRMED)** — keep jackin identity for **mark** (`j❯` / jackin❯) and **accent** phosphor (`#5CF07A` / muted `#1D9E75`) on brand moments only. **Structure, density, type, chrome = Apple-native.** Do not paint the whole app terminal-green or monospaced “construct” UI; that would break macOS native feel. |
| VS-14 | **Port jackin “construct / cyberpunk” DNA selectively (CONFIRMED intent)** — Desktop should feel like **jackin on a Mac**, not a website wallpaper. Extract tokens and motifs from brand/site; apply only where they raise recognition without hurting HIG legibility. Full matrix-rain hero is **marketing/landing**, not default Usage chrome. |

### 6.1b jackin brand extract → Desktop port map (from site + brand-identity)

**Source tokens** (docs / landing — dark identity anchor):

| Token | Value | Site use |
|---|---|---|
| Phosphor accent | `#5CF07A` | Chevron, links, primary CTAs (dark) |
| Phosphor muted | `#1D9E75` | Softer accent / light-mode usable green |
| Matrix rain green | `#00FF41` | **Rain + terminal mockups only** — not UI buttons |
| Canvas | `#0A0A0A` / `#050505` | Deep void backgrounds |
| Panel | `#0F1110` | Slightly lifted dark surfaces |
| Text | `#F4F7F5` / dim `#9CA8A1` / ghost `#5E6A64` | Hierarchy |
| Mono | JetBrains Mono | Mark, code, terminal |
| UI sans | Inter (site) → **SF Pro on Desktop** | Body UI |
| Sigil | `j❯` / `jackin❯` | Identity |
| Geometry brand | Square caps on **mark** | Terminal honesty |
| Ritual | Digital rain / construct intro | Landing & console ceremony |

**What to port to native Desktop (yes):**

| Motif | How on macOS Desktop |
|---|---|
| **j❯ monogram** | Empty status-item fallback; About; window traffic-area brand moment |
| **Phosphor accent** | Selection rings, primary “Open Usage” CTA, focus meter “healthy” optional tint, active account pill — not every label |
| **Mono digits** | Tabular mono (SF Mono / system monospacedDigit) for **% and time** — construct “instrument” feel inside Apple layout |
| **Deep void** | Dark-mode content canvas leaning warm-black (system window bg + subtle green-black mix, not pure matrix) |
| **Chevron language** | “Open details ›” using chevron; prompt-like quiet footer “jackin❯ desktop” |
| **Quiet rain** | **Optional** very subtle animated/static rain in **popover chrome edge or empty state only** (low opacity, Reduce Motion = off) — never behind readable text |
| **Construct ritual** | Not required for v1 usage bar; if ever, only idle/empty “no agents” state |

**What not to port wholesale (no):**

| Motif | Why |
|---|---|
| Full-screen digital rain behind content | Destroys legibility; un-Apple; competes with Liquid Glass |
| All-UI JetBrains Mono | Body UI stays SF Pro; mono only for metrics/mark |
| `#00FF41` on every control | Reserved rain/terminal; burns eyes; fails light mode |
| Square everything | Brand mark can stay sharp; **app chrome follows Apple continuous corners** |
| Terminal green-on-black walls of text | That’s the anti-pattern we already rejected |

**Blend formula (CONFIRMED intent):**

```text
Apple  = skeleton (layout, materials, type roles, spacing, glass chrome)
jackin = soul   (j❯, phosphor accent, mono metrics, deep canvas tint, optional rain whisper)
```

**Logo representation on Desktop:**

1. **Status chips / providers** — official third-party marks (template).  
2. **Fallback / empty** — `JackinMark` / **j❯** (existing PDF).  
3. **In-app brand** — small j❯ + “jackin❯ desktop” in mono/sans mix where Settings/About would put an app name.  
4. Never recolor jackin word green; chevron stays phosphor (brand-identity rule).

### 6.2 Research notes — “designed by Apple” on macOS (Tahoe era)

**Latest Apple quality bar (references):**

| Reference | Steal for Desktop |
|---|---|
| **HIG** | Clarity, deference, depth; hierarchy via layout |
| **Liquid Glass (WWDC25 / macOS Tahoe)** | Glass on **sidebar, toolbar, popover chrome, floating controls** — **not** on dense content lists |
| **System Settings** | Inset grouped lists; quiet section labels |
| **Music** | Large identity, trailing metrics, clear “See All” / detail links |
| **AppKit Tahoe patterns** | Glass sidebar + solid detail canvas; uniform toolbars |
| **SF Pro + semantic colors** | label / secondary / tertiary; red·orange·green for state |

**If Apple designed jackin❯ desktop (hypothesis for concepts):**

1. Bar: quiet dual-line chips, mono official logos, urgency on rim only.  
2. Popover: tall, grouped, **one primary number per account**, reset under, meter, per-account refresh.  
3. Usage window: split view, glass sidebar, **weekly hero**, other fields stacked in sections.  
4. **One** type/spacing/meter system across all three.  
5. jackin **j❯** on empty/fallback/About; phosphor for accents/CTAs, not full chrome.

### 6.2b Consistency contract (CONFIRMED intent)

| Element | Same on every surface |
|---|---|
| Provider identity | Official logo + display name |
| Account row | Label · % left · reset relative + date · meter · refresh |
| Primary metric | Large remaining % (bar also dual time stack) |
| Severity | System semantic (ok / warn / danger / depleted) |
| Open details | Obvious control, consistent wording |
| Type | SF Pro steps mapped once (title / body / subhead / caption) |
| Spacing | 8pt grid; same card padding |
| Materials | Glass = chrome only; content = standard fills |

### 6.3 HTML concept previews (active)

| Path | Role |
|---|---|
| [`plans/previews/desktop-ui/index.html`](./previews/desktop-ui/index.html) | Interactive mockups: anti-pattern, status bar, Overview A/B/C/E, Usage window D, open-path, **Concept F (Apple + jackin construct)** |

**How operator chooses:** open HTML in browser → reply `LIKE overview B`, `LIKE window D`, `LIKE open primary-button`, etc. Confirmed likes move to CONFIRMED layout direction.

**Other preview methods (optional later):** Figma/Sketch (Apple Design Resources kits), SwiftUI `#Preview`, live prototype screenshots. HTML remains the fastest for multi-concept compare.

**Known wrong today (not yet a CONFIRMED “must fix order,” but documented):**

- Glass helpers exist; popover + status bar largely do not use them.
- `StatusItemChip` computed but not painted as glass chips.
- Status-item click does not bind `popoverSelection` to that provider.
- Settings UI exists but is unreachable from the app graph.
- Display modes vs multi-item bar product model conflict.

### Critical bug — context menu disabled (operator report 2026-08-10)

| Field | Detail |
|---|---|
| **Symptom** | Right-click status item: Open Usage Window / Refresh / Quit jackin❯ desktop all **gray / not clickable** — cannot quit from menu |
| **Architecture class** | Menu item `target` is a controller that is **not retained** after `build()` — only `NSMenu` kept → target dies → AppKit disables items |
| **Structural fix** | `StatusBarController` **must retain** `StatusItemMenu` for the lifetime of the menu (not only the `NSMenu` graph) |
| **Status** | Fix applied in `DesktopAppDelegate.swift` / `StatusBarController` (retain `statusItemMenu`) — verify by rebuild + right-click |
| **Regression guard (PROPOSED)** | Comment + retain property; optional test that menu controller is owned by bar controller |

---

## 7. Architecture constraints (CONFIRMED — product law)

| ID | Decision |
|---|---|
| AR-1 | Swift is **display-only** — no HTTP/OAuth/second provider matrix; no invented percentages. |
| AR-2 | Rust owns probes, severity, strings, and (when built) **urgency ranking** for bar slots. |
| AR-3 | Limits-only export and UI (see `native/AGENTS.md`, `jackin-usage` rules). |
| AR-4 | macOS 26 `#available` / `glassEffect` only via `GlassFallbacks.swift`. |
| AR-5 | **SwiftUI only** for jackin❯ desktop UI surfaces (Apple *SwiftUI* technology overview). Structure Usage with `NavigationSplitView` + `.toolbar`; glance popover as SwiftUI panel chrome via `GlassFallbacks`. Do not introduce a second UIKit-first chrome stack. |
| AR-6 | Adopt Liquid Glass per Apple *Adopting Liquid Glass*: nav glass floats above content; content standard materials; scroll edges; toolbar grouping; glass sparingly; test light/dark + Reduce Transparency. |

---

## 7b. Feedback batch FB-1 (operator review of HTML concepts — 2026-08-10)

| ID | Feedback | Status |
|---|---|---|
| FB1-1 | **Phosphor** jackin styling — **liked strongly** | Keep / expand in blend concepts |
| FB1-2 | Product name: **`desktop` lowercase** → **jackin❯ desktop** (not “Desktop”); apply to product strings | CONFIRMED — repo product strings updated |
| FB1-3 | Apple + jackin representation — **liked overall** | Iterate on this family |
| FB1-4 | Footer **“construct · limits only”** — **remove**; does not belong | CONFIRMED reject |
| FB1-5 | Provider **tabs need progress underlines/meters** (Overview ok; OpenAI/Anthropic/Amp tabs should show weekly remaining track) | CONFIRMED required |
| FB1-6 | **Status bar** — no colored chip backgrounds/borders; **standard transparent macOS** status style (like other menu bar icons) | CONFIRMED |
| FB1-7 | **Usage window** concept — **liked**; must use **provider names** (OpenAI…) not Codex/Claude; **sidebar multi-account** | CONFIRMED |
| FB1-8 | **Liquid Glass** where it makes sense | CONFIRMED direction |
| FB1-9 | **Overview** — liked a lot; keep iterating | CONFIRMED direction |
| FB1-10 | Focus next: **Concept C Music-list** with **Overview + Providers** tabs; Providers = list of all available providers | CONFIRMED focus for next preview |
| FB1-11 | **Status transparent** — liked | CONFIRMED |
| FB1-12 | Overview: **no** second row of Overview/OpenAI/Anthropic/Amp tabs — only the provider inventory blocks | CONFIRMED |
| FB1-13 | Providers tab: **that** is where provider strip lives; select provider → **full Capsule-parity detail** (same depth as current app: accounts, updates, Spark, resets date/time, limit reset credits, session/weekly, model windows, reserve/pace, etc.) | CONFIRMED |
| FB1-14 | Multi-account: one **line/block per account** always (including 0%); account switch keeps **consistent** detail layout | CONFIRMED |
| FB1-15 | j❯ / jackin mark in preview looked **wrong** — fix monogram representation | Fixed in preview (green block · black j · white chevron) |
| FB1-16 | Popover + transparent status bar — **good overall** | CONFIRMED direction |
| FB1-17 | Provider strip tabs — **center** (not left-weird) | CONFIRMED |
| FB1-18 | **desktop** word different color from jackin❯ (e.g. white/primary label) | CONFIRMED intent |
| FB1-19 | **Light + dark mode** required for all chrome | CONFIRMED |
| FB1-20 | Metrics (% + meters) — **not** multi-provider rainbow; prefer **jackin 1–2 color** system (phosphor + quiet). **Logo plates only** carry distinct brand colors | CONFIRMED |
| FB1-21 | Providers strip may still use colored **logos** for identity | CONFIRMED |
| FB1-22 | Real OpenAI / Anthropic / Amp icons required for final look | CONFIRMED goal (official assets; preview uses stand-in SVG until kits land) |
| FB1-23 | HTML visual reference = source of truth for craft until Swift ships; agents use it for look/feel | CONFIRMED process |
| FB1-24 | Provider strip + account switcher: **centered**, **horizontal scroll** when many items (same interaction idea as today) | CONFIRMED |
| FB1-25 | % + progress meters: **only 3 colors by status level** (high / medium / low remaining) — **not** per-provider brand colors | CONFIRMED |
| FB1-26 | Popover craft **almost final** — logos OK; next surface after freeze = **Usage window** | CONFIRMED sequencing |
| FB1-27 | Status color bands (implementation default until tuned): **high ≥ 40%**, **medium 15–39%**, **low &lt; 15%**, **0% depleted** (grey) | PROPOSED — confirm if needed |
| FB1-28 | **Provider strip** stays **centered** (+ horizontal scroll when many) | CONFIRMED |
| FB1-29 | **Account chips** stick **left** (not centered); horizontal scroll when many | CONFIRMED |
| FB1-30 | Providers detail must follow **real Rust bucket templates** per surface (OpenAI, Anthropic, Amp, xAI, Kimi, Z.ai, MiniMax) from `usage_bucket_order` / probes — full Capsule-parity fields | CONFIRMED |
| FB1-31 | **Reset line separation:** relative reset + exact date/time always on **their own line(s)** — never jammed with % used, pace, deficit, or run-out | CONFIRMED |
| FB1-32 | **Auth / credential origin is first-class detail** per account. App UI shows **only** the credential source string (exact winning path/env/Keychain). No “how jackin decided” / resolver narrative in the app — that belongs in docs | CONFIRMED |
| FB1-33 | Popover craft **liked overall** — keep polishing Apple+jackin; next major surface = Usage window after final OK | CONFIRMED |
| FB1-34 | **Credential source** = exact winning Rust `credential_origin` only (e.g. `OAuth · ~/.codex/auth.json`). Never disjunctions; never explain resolution order in-app | CONFIRMED |
| FB1-35 | HTML visual ref + decisions + `AGENT_HANDOFF.md` = **canonical design package** for implementer agents | CONFIRMED |
| FB1-36 | **Popover design track complete** for planning reference (operator: rest looks great); next design track = **Usage window / full app** | CONFIRMED |
| FB1-37 | **Status left-click** → popover with **Providers + that provider + account** focused (never Overview). HTML flow demo required | CONFIRMED (reaffirm SB-23–26) |
| FB1-38 | **Status right-click** → glass context menu: Open Usage Window · Refresh · Quit (enabled) | CONFIRMED |
| FB1-39 | **Usage window** design track open: glass **sidebar + toolbar**; solid content; multi-account nest; same tokens as popover | CONFIRMED direction |
| FB1-40 | Design must stay **Liquid Glass–consistent** (glass = nav only; solid content; transparent menu bar items) | CONFIRMED re-verify |
| FB1-41 | **One popover artifact:** status interaction and standalone craft use the **same** `popover.html` (embed via `?embed=1&mode=providers&provider=…`). No mini-pop reimplementation in hub or native | CONFIRMED |
| FB1-42 | **Soft scroll edges:** vertical detail/overview + horizontal provider/account strips dissolve at edges — never hard mid-card / mid-tab clip. Native: `scrollEdgeEffect(.soft)` under glass chrome and above footer dock | CONFIRMED |
| FB1-43 | **Open Usage Window CTA** = glass capsule + phosphor tint/hairline (not solid green slab); lives in sticky glass **footer dock** outside scrollers | CONFIRMED |
| FB1-44 | Popover layout = sticky **chrome** (brand+seg[+provider strip]) + flex scroller + sticky **footer dock** — content scrolls between glass layers | CONFIRMED |
| FB1-45 | **Usage window craft:** native macOS utility shell (quality bar set by apps like **Surge Dashboard**): unified glass titlebar + traffic lights, glass sidebar with section labels + trailing %, solid content, **metric tile row**, Settings-style inset groups, soft scroll edges. Not a flat web split-pane. | CONFIRMED direction |
| FB1-46 | Usage window keeps jackin law: phosphor selection/j❯, 3-level status only, credential source only, limits only (no spend/trends) | CONFIRMED |
| FB1-47 | **Usage sidebar = Liquid Glass nav** (Finder/Tahoe): translucent fill + strong blur/saturate + hairline/specular; window shell transparent so stage bleeds under sidebar; **content pane solid** for contrast | CONFIRMED |
| FB1-48 | **Provider vs account are distinct systems:** provider = primary full-fill + brand plate + mini meter; account = soft inset **radio well** (sidebar nest) + left **chip strip** (detail, multi-account only) with phosphor **tint**/radio — never provider full-fill, never solid green slab, never logo plate/mini-meter on accounts | CONFIRMED |
| FB1-49 | **Multi-layer Liquid Glass chrome** (Telegram + Finder/Tahoe patterns): specular top wash + translucent fill + hairline + ambient bleed; floating inner list well (`.side-well`); capsule glass toolbar controls; solid content contrast preserved | CONFIRMED |
| FB1-50 | Reference map for LG app patterns lives in `plans/previews/desktop-ui/LIQUID_GLASS_REFERENCES.md` — craft guidance, not a third-party pixel clone | CONFIRMED |
| FB1-51 | **Usage IA: no duplicate limits** — each limit appears once (single limit list). No metric tiles + full buckets repeating the same %. Titlebar does not restate the content page title/account. | CONFIRMED |
| FB1-52 | **Usage chrome is continuous Liquid Glass:** one full-width glass titlebar; sidebar floats with soft depth (no hard vertical pane rule); content solid underneath — Safari-like seamlessness, not a 4-quadrant web split | CONFIRMED |
| FB1-53 | **Visual HTML package is finished craft SoT** — no LIKE/DISLIKE polls in HTML; craft is shown, not voted. Decisions stay in this markdown file; HTML encodes them visually | CONFIRMED |
| FB1-54 | **Fixture data must match `jackin-usage` host presentation:** status bar / sidebar glance = Weekly (or Daily for Amp) only; Usage window = full `usage_detail_presentation` buckets + metadata; same account’s glance % identical across bar, sidebar trail, and Weekly/Daily detail row. Map: `plans/previews/desktop-ui/DATA_CONTRACT.md` | CONFIRMED |
| FB1-55 | **Official Apple Liquid Glass + SwiftUI stack is binding:** §6.0 **LG-A1–LG-A12**, **AR-5**, **AR-6**, **VS-1 CONFIRMED**. Craft HTML must illustrate those principles; native must implement via SwiftUI + `GlassFallbacks` only | CONFIRMED |
| FB1-56 | **Status bar dual stack shipped:** top = compact form of Rust `reset_label` (no invented durations); bottom = Rust `bar_label` glance %; **template mono icons**, no glass chips (LG-A1 + FB1-6) | CONFIRMED |
| FB1-57 | **Usage window native layout:** `NavigationSplitView` glass sidebar + solid detail; provider rows show trailing `barLabel` (matches bar); account switcher left H-scroll pills in content; buckets/metadata as content cards only (LG-A2/A3/A8) | CONFIRMED |
| FB1-58 | **Glance popover is translucent Liquid Glass:** clear `NSPopover` window + `GlassFallbacks.panelSurfaceBackground` (regular glass / ultraThinMaterial fallback); soft separators; glass refresh dock; content rows stay standard fills — wallpaper must peek through the shell | CONFIRMED |
| FB1-59 | **Usage window is one continuous surface** — content fills the window; glass sidebar + toolbar **float on top** (Apple LG / Telegram macOS), not a hard header+sidebar+content three-pane split. Native: floating `NavigationSplitView` sidebar + `backgroundExtensionEffect` under detail | CONFIRMED |
| FB1-60 | **De-slop craft rules:** no one-sided borders (always full continuous stroke or none); no multi-layer gradient “AI pill” stacks on every control; no orphan left accent bars; prefer fill + complete capsule/rect stroke; 8pt rhythm; hierarchy via type, not decorative chrome | CONFIRMED |
| FB1-61 | **Liquid Glass craft target = latest stable macOS only (Tahoe 26)** — verify Usage + status popover + bar against LG-A1–A12 on Tahoe; pre-26 paths are Reduce Transparency / compile fallbacks only, not a second design. Soft scroll edges + no stacked system+custom glass on sidebar | CONFIRMED |

### One-by-one queue (after FB-1)

1. ~~Provider identity / popover craft~~ — near final (await operator “perfect”)  
2. **Next:** Usage window (multi-account sidebar, full detail, light/dark)  
3. Official logo asset ingestion  
4. Implementation plans via improve skill  

### Apple + jackin quality pass (advisor review — 2026-08-10)

As if shipping on macOS Tahoe with jackin soul:

| Check | Verdict | Action |
|---|---|---|
| Hierarchy (primary % vs meta) | Good | Keep hero % large; reset on own line (FB1-31) |
| One-line cram | Improving | Pace/used never share line with reset |
| Materials (glass chrome) | Good | Popover glass; content solid |
| Consistency across providers | Good | Same account → bucket → auth block pattern |
| Auth honesty | Critical | Surface `credential_origin` richly (file / Keychain / env) — FB1-32 |
| Status colors | Good | 3 levels only for meters |
| Light/dark | Good in HTML | Keep dual tokens into Swift |
| Touch/click targets | OK | Refresh 28pt; pills tall enough |
| Motion | Light | Optional rain whisper only; respect Reduce Motion |
| Brand blend | Good | j❯ + phosphor accent; not full matrix |
| Still improve later | — | Official logos; exact reset clock when Rust has `resets_at`; Usage window craft |

**Rust note:** `FocusedAccountHeader.credential_origin` already exists — UI must show **that string only**. If origin is too coarse (only “OAuth”), extend probe strings so the origin is the exact winning source (implementation phase). No in-app resolver essay.

## 8. Confirmation log

Append-only record of operator confirmations.

| Date | What | Result | Notes |
|---|---|---|---|
| 2026-08-10 | Philosophy: forward, no ROI, ambitious refactor OK | **CONFIRMED** | §2 |
| 2026-08-10 | Bug = architecture class; prefer structural fix | **CONFIRMED** | §2 |
| 2026-08-10 | Status bar: burn-first, max 3, compact, color priority, real logos | **CONFIRMED** | §4.1, §5.1 |
| 2026-08-10 | Store decisions in markdown for planning reference | **CONFIRMED** | This file + §1 process |
| 2026-08-10 | Dual-line chip: time (hours-first) + remaining %; waste-first rank; dynamic top | **CONFIRMED** | §4.1a SB-7–SB-16 |
| 2026-08-10 | Rank **soonest-then-remaining** | **CONFIRMED** | SB-17 |
| 2026-08-10 | Time ladder **48h** (m / h / d) | **CONFIRMED** | SB-18 |
| 2026-08-10 | **Hide 0%** from burn bar | **CONFIRMED** | SB-19 |
| 2026-08-10 | Driving window **Weekly-first**; no-weekly → provider primary non-session (e.g. Amp Daily); session off bar | **CONFIRMED** | SB-20–SB-22 |
| 2026-08-10 | Detail for provider/account in **popover** (not bar) | **CONFIRMED** | SB-22 |
| 2026-08-10 | Bar chip click → popover focused on **that provider + account**; taller, little scroll | **CONFIRMED** | SB-23–SB-28 |
| 2026-08-10 | **No implementation plans until all decisions finalized** — collect vision first | **CONFIRMED** | §1 step 5 |
| 2026-08-10 | Freeze: “explained everything?” → **full grill** → answers → “decisions complete” → **then** improve plans | **CONFIRMED** | §1 step 6 |
| 2026-08-10 | Overview redesign: simple weekly, multi-account + meters, per-account refresh, no global footer, craft quality | **CONFIRMED** | §4.1c OV-1–OV-13 |
| 2026-08-10 | Usage window: **data correct**, presentation **rejected** — redesign craft; open path must be obvious | **CONFIRMED** | §4.1e UW-1–UW-5 |
| 2026-08-10 | No one-line cram; Apple-like space/hierarchy; pick layout via HTML previews | **CONFIRMED** | §6.1 VS-5–VS-8 |
| 2026-08-10 | Consistent system everywhere; luxury Apple-native craft; importance hierarchy; jackin accent blended | **CONFIRMED** | VS-9–VS-13 |
| 2026-08-10 | LIKE status transparent; popover C+ IA; 2-color meters; centered strip; light/dark ref | **CONFIRMED** | FB1-11–23 |
| 2026-08-10 | Port construct DNA selectively (phosphor, j❯, mono metrics, optional quiet rain); not full matrix UI | **CONFIRMED** | VS-14 + §6.1b |
| 2026-08-10 | Primary UI names = provider (OpenAI, Anthropic, Amp…); per-provider color; one-by-one decisions | **CONFIRMED** | LG-5–LG-7 |
| 2026-08-10 | Phosphor jackin accent liked; product title **jackin❯ desktop** (desktop lowercase); drop construct footer tagline | **CONFIRMED** | FB-1 batch |
| 2026-08-10 | Overview direction liked (iterate); status bar transparent system-style; Usage window + multi-account sidebar; tab meters; Concept C providers list | **CONFIRMED** | FB-1 batch |
| 2026-08-10 | Credential source only (no resolver narrative) | **CONFIRMED** | FB1-32/34 |
| 2026-08-10 | **§0 agent/HTML source-of-truth stack for `/goal`** | **CONFIRMED** | §0 |
| — | Idle/auth on bar, missing reset, meter bands exact numbers | **OPEN** | §4.3 / FB1-27 |
| — | PDF template as ship format | **PROPOSED** | §5.2 — needs explicit confirm |

---

## 9. How to confirm something (operator cheat sheet)

**One-by-one mode (preferred now):**

```text
LIKE: …
DISLIKE: …
CHANGE: …
```

Or short: `LIKE primary OpenAI/Anthropic names` / `DISLIKE monograms`.

**Batch mode (later):**

```text
CONFIRM LG-P1 PDF template
REJECT SB-P3 logo-only beads
```

Agent updates this file the same turn.

---

## 10. Decision-collection queue (no plans yet)

**Phase:** vision / decisions only.

**Do not** run improve plan generation until:

```text
operator: “I explained everything. Do you have any questions?”
  → full grill (advisor)
  → operator answers → file updated
operator: “decisions complete” / “generate plan from decisions file”
  → improve skill → plans
```

### Grill seed list (used when operator triggers the grill — not a plan)

**A — Bar edge cases:** SB-O4 auth/error · SB-O5 idle · SB-O6 % left hard-lock · SB-O9 missing reset · SB-P1 Rust rank · SB-P4 color chrome · multi-account auto vs selected (SB-25 clarity)

**B — Logos:** LG-O1–O5 format, mono/color, missing kits, acquisition, legal

**C — Overview / popover craft:** OV-13 pixel density · click account row → select + open provider tab? · refresh spinner placement · provider tab redesign in same pass or Overview only first?

**C2 — Usage window:** UW-O1 how to open (obvious affordance) · UW-O2 focus provider+account · UW-O3 popover provider tab vs window as full detail · craft tokens shared with Overview

**D — Surfaces:** right-click menu · Settings/modes · Liquid Glass / craft scope (VS-*) · what is explicitly out of this program

**E — Contradictions / completeness:** walk all CONFIRMED for gaps; no OPEN left that plans would need

---

*Last updated: 2026-08-10 — §0 source of truth for /goal agents; HTML+decisions package is acceptance oracle.*
