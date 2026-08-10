# QI (Quality Integration) verification — HTML SoT ↔ native jackin❯ desktop

**Audience:** a `/goal` (or equivalent) implementer agent that must **close visual and interaction parity**, not only compile green.  
**Oracle:** HTML design SoT under `plans/previews/desktop-ui/` (+ decisions).  
**Companion:** [UI_PARITY_MASTER.md](./UI_PARITY_MASTER.md) (program of record).

This document is the **detailed integration-verification playbook**. Follow it every phase of implementation. If a step fails, fix code and re-run the loop — do not declare success on harness-only green.

---

## 1. Why QI exists

Automated unit/harness tests prove **data paths and architecture law**. They do **not** prove the product **looks** like `index.html` / `popover.html`.

| Layer | Proves | Does not prove |
|---|---|---|
| Structural Python / lint / SoT harness | Invariants, glass gate, selection rules | Spacing, materials, hierarchy “feel” |
| Unit tests of pure helpers | Correct selection/inventory/URLs | On-screen layout |
| **QI visual + interaction** | Look/feel/IA vs HTML SoT | — |

**Bare minimum success:** native status bar + popover + Usage are **the same design** as the HTML reference (IA, hierarchy, chrome roles, interactions, limits-only). “Better” only if still the same design system (native Tahoe LG done correctly).

---

## 2. Verification pyramid (use all layers)

```
        ┌─────────────────────────────┐
        │  L5 Operator / agent sign-off│  VISUAL_QA_LOG + optional human
        ├─────────────────────────────┤
        │  L4 Screenshot / multimodal  │  HTML baseline ↔ native capture
        ├─────────────────────────────┤
        │  L3 Interaction walkthrough  │  Click paths, focus, menus
        ├─────────────────────────────┤
        │  L2 Pure + architecture gates│  DesktopSoTParityHarness, etc.
        ├─────────────────────────────┤
        │  L1 Structural SoT           │  check_usage_liquid_glass.py
        └─────────────────────────────┘
```

A phase is **not done** until **L1–L4** pass for that surface (L5 when operator is available). Headless CI without GUI may stop at L1–L2 and mark L3–L4 **blocked** — never invent Pass.

---

## 3. Research-backed techniques (what agents should use)

Industry practice for “UI matches the design” (2025–2026):

| Technique | Typical tools | Fit for jackin❯ desktop |
|---|---|---|
| **HTML / web visual baselines** | [Playwright `toHaveScreenshot`](https://playwright.dev/docs/test-snapshots), BackstopJS, Percy/Chromatic | Capture **SoT panels** from `index.html` / `popover.html` as reference images agents compare against |
| **Native UI snapshots** | [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing), SwiftUI PreviewSnapshots, Prefire | Snapshot **isolated SwiftUI views** (popover body, Usage sidebar row, detail card) under fixed size/theme — not the whole menu bar |
| **E2E UI automation + media** | XCUITest / XCUIAutomation ([Apple WWDC25](https://developer.apple.com/videos/play/wwdc2025/344/)): screenshots/video on run | Drive Usage window open, capture window; fragile for `NSStatusItem` |
| **Screen capture scripts** | macOS `screencapture`, `osascript` | Capture live status bar / popover when app is running |
| **Multimodal review** | Agent `read_file` on PNG/JPEG (vision) | **Primary agent QI step:** open HTML screenshot + native screenshot and list deltas |
| **DOM/a11y structure** | Playwright accessibility tree; XCTest accessibility queries | Parity of labels, roles, hierarchy without pixels |
| **Semantic visual AI** | Applitools / Autonoma-class tools | Optional later; not required for this plan |

### What works best for *this* product

1. **HTML is web** → Playwright (or Safari + `screencapture`) can produce **stable SoT baselines** of the craft hub.  
2. **Native is menu-bar agent** → full-app pixel CI is hard (status items live in system menu bar). Prefer:
   - **Structural + pure gates** always  
   - **SwiftUI view snapshots** for popover content and Usage subviews (when Xcode available)  
   - **Live screencapture + multimodal compare** for integration QI on a real Mac  
3. **Never** require cloning system  / Control Center pixels — only our extras + app windows/popovers.

### Agent multimodal workflow (recommended)

Industry agents treat visual regression as a **feedback loop**: capture → compare → list diffs → fix → recapture ([self-testing agent pattern](https://stevekinney.com/courses/self-testing-ai-agents/visual-regression-as-a-feedback-loop)).

For jackin❯:

```
1. Capture HTML baseline PNG(s) for a named scene (dark/light)
2. Capture native PNG(s) for the same scene (or closest hostable view)
3. read_file both images (vision)
4. Emit structured delta list mapped to master plan gap IDs (G-P3, G-U4, …)
5. Implement only those deltas
6. Re-capture native; re-read; delta list must shrink
7. Stop when matrix Pass or only N/A system-chrome remains
```

**Do not** update “baselines” to match a worse native — fix native toward HTML.

---

## 4. Artifact layout (durable QI evidence)

Implementer creates and keeps under the repo or goal scratch (never shared `/tmp`):

```
advisor-plans/qi-artifacts/          # preferred in-repo for PR review (optional)
  README.md                          # index of scenes + dates
  html/
    status-desktop-dark.png
    status-desktop-light.png
    usage-window-dark.png
    usage-window-light.png
    popover-openai-dark.png
    popover-openai-light.png
    popover-anthropic-dark.png
    …
  native/
    status-bar-dark.png              # if capturable
    popover-openai-dark.png
    usage-overview-dark.png
    usage-openai-detail-dark.png
    …
  deltas/
    2026-08-10-popover-openai.md     # structured multimodal notes
```

Scratch (ephemeral goal dir) may hold the same tree during a `/goal` run; **promote** important PNGs into the PR or attach to VISUAL_QA_LOG.

Naming convention: `{surface}-{variant}-{theme}.png`  
Examples: `popover-codex-a1-dark.png`, `usage-nest-openai-light.png`.

---

## 5. Scene catalog (must capture / compare)

Every scene is **fixture-driven** where possible (same numbers as DATA_CONTRACT: OpenAI 57%, Anthropic 12%, Amp 100%, multi-account a1/a2).

| Scene ID | HTML how to open | Native how to open | Themes |
|---|---|---|---|
| `status-desktop` | `index.html` → Status interactions panel | Live menu bar with ≥2 status items | D/L |
| `popover-overview` | `popover.html` Overview | Left-click fallback or Overview tab | D/L |
| `popover-openai` | Hub click OpenAI / `?provider=openai` | Left-click OpenAI status item | D/L |
| `popover-anthropic` | Hub click Anthropic | Left-click Anthropic item | D/L |
| `popover-multi-acct` | OpenAI with a1/a2 in popover.html | Multi-account codex if credentials exist; else fixture store | D/L |
| `usage-overview` | Usage panel, Overview nav | Open Usage → Overview | D/L |
| `usage-provider-nest` | Usage, OpenAI expanded accounts | Select OpenAI; nest visible | D/L |
| `usage-detail-openai` | Usage detail OpenAI a1 | Select account a1; full buckets | D/L |
| `usage-toolbar` | Usage chrome-float / titlebar | Usage key window titlebar+Refresh | D/L |
| `ctx-menu` | Right-click mock on hub | Right-click status item | D (min) |

---

## 6. Capture recipes

### 6.1 HTML baselines (always available)

**Option A — Playwright (preferred for agents, automated)**

```bash
# Example sketch — implement under plans/previews/desktop-ui/qi/ when coding starts
npx playwright test --config=plans/previews/desktop-ui/qi/playwright.config.ts
# Specs open file://…/index.html, set data-theme, click panels, toHaveScreenshot
```

Record baselines once from the **frozen HTML SoT**. Treat HTML snapshots as **oracle**, not renegotiable, unless the design SoT HTML itself changes in the same PR.

**Option B — Manual / scripted Safari**

```bash
# Open file URL in browser, then:
screencapture -l$(osascript -e 'tell app "Safari" to id of window 1') html/status-desktop-dark.png
```

Or full-window capture after positioning the hub.

### 6.2 Native captures (when app runs)

**Window (Usage):**

```bash
# After Usage is frontmost:
screencapture -l$(osascript -e 'tell app "System Events" to get id of first window of process "JackinDesktop"') \
  native/usage-overview-dark.png
```

**Popover:** hard to capture reliably; prefer:
- Host `PopoverRoot` in a **debug window** / SwiftUI Preview at fixed 412×560 and snapshot that view, **or**
- `screencapture -R x,y,w,h` region after left-click (document region in deltas note)

**Status bar:** full menu-bar strip:

```bash
screencapture -R 0,0,$(osascript -e 'tell application "Finder" to get item 3 of (get bounds of window of desktop)'),24 \
  native/status-bar-dark.png
```

(Adjust for menu bar height / notch / scale — record display scale in VISUAL_QA_LOG.)

### 6.3 Isolated SwiftUI snapshots (Xcode path)

When full Xcode is available, add snapshot tests for:

- `PopoverRoot` (or provider tab) @ 412×560, light/dark  
- `UsageWindowRoot` sidebar+detail @ 920×620  
- Single `ProviderCardView` with fixture `UsageDetailPresentation`

Libraries: Point-Free **swift-snapshot-testing**, DoorDash **PreviewSnapshots**, or Prefire from previews.

**Fixture data:** inject fixed `PresentationStore` / model fixtures (57% / 12% / 0%) so snapshots are stable — never live network in QI snapshots.

---

## 7. Multimodal comparison protocol (agent must follow)

For each scene in §5 with both HTML and native images:

### 7.1 Read order

1. `read_file` HTML PNG (vision)  
2. `read_file` native PNG (vision)  
3. Optionally re-open HTML source section for the scene (structure)

### 7.2 Emit structured delta (required format)

Write `advisor-plans/qi-artifacts/deltas/{date}-{scene}.md`:

```markdown
# QI delta: {scene-id} · {theme}

## Oracle
- HTML: qi-artifacts/html/{file}.png
- Source: index.html | popover.html § …

## Candidate
- Native: qi-artifacts/native/{file}.png
- Code: {paths}

## Same (keep)
- …

## Different (must fix unless N/A)
| Severity | Element | HTML | Native | Gap ID | Action |
|----------|---------|------|--------|--------|--------|
| High | Account nest | mini meter under % | % only | G-U4 | add meter |
| Med | Popover width | ~424 dense | sparse | G-P1 | tighten spacing |
| N/A |  menu | mock | system | — | do not clone |

## Verdict
Fail — remaining High: …
# or Pass
```

### 7.3 Comparison checklist dimensions

Agents must score each dimension **explicitly** (not vibes-only):

| Dimension | Look at |
|---|---|
| **IA / hierarchy** | What is primary vs secondary? Provider vs account? |
| **Chrome roles** | Glass nav vs solid content? Status template mono? |
| **Typography** | Title vs caption vs mono % |
| **Spacing / density** | Crowded vs sparse vs HTML |
| **Materials** | Translucent shell? Solid cards? No glass on data? |
| **Color / status** | High/mid/low / depleted; phosphor only on allowed roles |
| **Meters** | Fill ≈ remaining %; 0% empty |
| **Copy / data** | Labels and % match DATA_CONTRACT fixtures |
| **Interaction affordances** | Radio vs full-fill; Refresh placement; Open usage |

### 7.4 Pixel-diff optional helper

If available, compute rough diff for agent triage (not sole Pass/Fail):

```bash
# ImageMagick example (if installed)
compare -metric AE html/popover-openai-dark.png native/popover-openai-dark.png null: 2>&1
```

High AE → force multimodal read. Low AE is not automatic Pass if IA is wrong (e.g. wrong hierarchy with similar colors).

---

## 8. Interaction QI (not just static look)

For each interaction, script or manually execute and log result:

| Flow | Steps | Pass |
|---|---|---|
| Status → popover focus | Left-click Anthropic, then OpenAI | Body switches; selection matches item |
| Status → menu | Right-click; invoke Open Usage | Usage opens; menu items enabled |
| Popover → Usage | Open Usage from header/CTA | Window focuses correct surface |
| Popover account switch | Multi-account chips | Detail + glance % update (selected account) |
| Usage nest | Select provider | Accounts appear under it with meters |
| Usage account select | Radio a1 → a2 | Detail + trail % change; bar contract if applicable |
| Usage Open usage page | Click control | Browser opens OFFICIAL URL for surface |
| Activation | Open Usage; close all windows | Regular then accessory; status items remain |
| Refresh | Toolbar / View / popover footer / ⌘R | Spinners/labels update without inventing % |

Log to `VISUAL_QA_LOG.md` Interaction section.

---

## 9. Build → check → fix loop (mandatory for `/goal`)

```
┌──────────────┐
│ 1. Open HTML │  freeze scene in mind / capture baseline
└──────┬───────┘
       ▼
┌──────────────┐
│ 2. Implement │  smallest change toward one Gap ID
└──────┬───────┘
       ▼
┌──────────────┐
│ 3. L1+L2     │  python check + native harnesses (must pass)
└──────┬───────┘
       ▼
┌──────────────┐
│ 4. Capture   │  native PNG for that scene (or view snapshot)
└──────┬───────┘
       ▼
┌──────────────┐
│ 5. Multimodal│  read HTML + native; write delta file
└──────┬───────┘
       ▼
   High deltas? ──yes──► back to 2
       │ no
       ▼
┌──────────────┐
│ 6. Mark Pass │  matrix row + commit -s + push
└──────────────┘
```

**Rules:**

- One Gap ID cluster per commit when possible.  
- Never “batch implement entire app” then verify once.  
- If L1/L2 fail, do not bother with screenshots until green.  
- If L4 fails with only Low/Med polish left, continue until High is zero before claiming phase complete.

---

## 10. `/goal` agent brief (paste into goal prompt)

When launching implementation via `/goal`, include:

```
Implement jackin❯ desktop UI parity per advisor-plans/UI_PARITY_MASTER.md
and advisor-plans/QI_VERIFICATION.md.

Oracle: plans/previews/desktop-ui/index.html + popover.html (Dark+Light).
Do not invent design. Build → L1/L2 gates → capture → multimodal compare
→ fix → recapture until §6 matrix has no High fails.

Evidence required:
- qi-artifacts or scratch screenshots for each scene you claim Pass
- structured delta files for each Fail→Pass cycle
- harness logs (ArchitectureLint, SoTParity, ParityMatrix, HTML check)

Stop conditions: from UI_PARITY_MASTER §12.
Brand: jackin❯ desktop. Glass only via GlassFallbacks. Limits only.
```

---

## 11. Environment tiers

| Tier | What agent can do | Required for program Done? |
|---|---|---|
| **CLT only** (no full Xcode) | L1, L2; no reliable live app UI | No — leave L3/L4 blocked with log |
| **Xcode + Mac GUI** | L1–L4; screencapture; optional snapshots | **Yes** for full Done |
| **Xcode + Playwright** | Automated HTML baselines + native manual/snap | Best |

Honest `manual-launch.txt` / blocked L4 is correct when GUI is missing. **Do not fake green visual Pass.**

---

## 12. Definition of QI done (per phase / program)

**Per phase (B/C/D):**

- [x] All Gap IDs in that phase High = Pass
- [x] L1 + L2 green
- [x] At least one HTML + one native capture per primary scene (or explicit blocked)
- [x] Multimodal delta file with Verdict Pass

**Program:**

- [x] All of §5 scenes addressed
- [x] VISUAL_QA_LOG sign-off (agent + operator if available)
- [x] No High residual in master residual table
- [x] Harnesses green

---

## 13. Anti-patterns (agents must not)

| Anti-pattern | Why forbidden |
|---|---|
| Declare Pass on harness-only | Design SoT not verified |
| Update HTML to match bad native | Oracle inversion |
| Pixel-match system  / Control Center | Not our chrome |
| Live network data in snapshots | Non-deterministic |
| Re-implement UI in tests | Test theater |
| Single giant PR without delta files | No QI trail |
| Glass chips on status bar to “match glass HTML sidebar” | Wrong layer (FB1-6) |

---

## 14. References

- Playwright visual comparisons: https://playwright.dev/docs/test-snapshots  
- Point-Free swift-snapshot-testing: https://github.com/pointfreeco/swift-snapshot-testing  
- Apple XCUIAutomation / screenshots: https://developer.apple.com/documentation/xcuiautomation  
- WWDC25 UI automation media: https://developer.apple.com/videos/play/wwdc2025/344/  
- Self-testing agents / visual regression loop: https://stevekinney.com/courses/self-testing-ai-agents/visual-regression-as-a-feedback-loop  
- Project SoT: `plans/previews/desktop-ui/*`, `plans/desktop-design-decisions.md`
