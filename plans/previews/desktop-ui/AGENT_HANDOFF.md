# Agent handoff: HTML visual reference → native macOS Swift

> **Canonical stack:** `plans/desktop-design-decisions.md` **§0** is the product-level source-of-truth law. This file is the procedural companion for implementers.  
> Used when operator runs **`/goal`** (or improve execute) against the desktop visual package.

## Is HTML good enough?

**Yes as a primary craft reference**, if it is **repo-local, tokenized, dual-theme, and paired with written rules**. It is **not** enough alone for pixel-perfect Liquid Glass or trademark logos.

Industry pattern (2025–2026 AI-native design handoff):

1. **Mockup lives in the repo** (HTML/CSS beside code) so agents open it like source.  
2. **Design tokens** (CSS variables / DTCG-style) map 1:1 to implementation (Swift `Color`, SF fonts, spacing).  
3. **Semantic rules** in markdown (what is primary vs quiet, glass vs content).  
4. **Verification gates**: screenshots dark+light, architecture lint, harnesses.  
5. Optional later: Figma tokens, vision model compare of screenshots.

HTML alone without tokens becomes “generic SaaS.” Tokens alone without a composed screen become “random HIG.” **We ship both.**

## What this folder provides

| Artifact | Role |
|---|---|
| [`popover.html`](./popover.html) | **Glance popover SoT** (Overview + all 7 providers, Liquid Glass chrome). Status left-click uses `?embed=1&mode=providers&provider=…` |
| [`index.html`](./index.html) | Hub: status interactions (iframe → popover.html), **Usage window** (native shell: titlebar + glass sidebar + metric tiles + Settings groups), Liquid Glass check |

### Usage window (FB1-45 / FB1-47 / FB1-48)

Quality bar = Finder/Tahoe Liquid Glass + high-end native macOS utilities (e.g. Surge Dashboard), not generic web admin UI.

| Layer | Material | Notes |
|---|---|---|
| Window shell | Transparent | Stage bleeds under glass (blur has something to refract) |
| Titlebar | One continuous glass strip | Safari-like; traffic lights + brand + Usage + Refresh — **no split panes** |
| Sidebar | Floating glass | Soft shadow only — **no hard vertical rule** between side and content |
| Content | Solid | Single **limit-list** + one quiet details group — **no tiles+buckets dupes** |
| Provider row | Primary nav | Full-fill + brand plate + name; multi-account caption; **no** glance %/meter |
| Account row | Secondary under selected provider | Soft inset nest; glance % + mini meter; radio when multi; mono labels; **no** detail chip strip dupe |
| Scroll | Soft edges | Dissolve under chrome |

**Do not** ship a flat two-column web panel without window chrome.  
**Do not** use the same selection chrome for provider and account rows.  
**Do not** restate the same limit % in two content components.
| CSS custom properties | Named tokens agents must map to Swift |
| [`README.md`](./README.md) | Operator + implementer rules |
| This file | Predictable agent process |
| [`../../desktop-design-decisions.md`](../../desktop-design-decisions.md) | Product law (CONFIRMED IDs) |

**Hard rule (FB1-41):** never reimplement a simplified mini-pop for status click. Native and HTML both open the full popover craft.

## How to get predictable agent output

### Do

1. Point the agent at **decisions file + this HTML** in the same prompt.  
2. Require **token mapping table** in the plan (CSS var → Swift).  
3. Require **screen-by-screen** implementation: bar → Overview → Providers detail.  
4. Require **dark + light** verification.  
5. Require **no invented credential text** — only `credential_origin` and related Rust fields.  
6. Use **screenshot compare** after SwiftUI build against HTML (human or vision).  
7. Keep **GlassFallbacks** as sole glass gate (repo rule).  
8. Use **soft scroll edge effects** under glass chrome / above footer (FB1-42) — never hard-clip scrolling content.  
9. Open Usage CTA = **glass capsule** (FB1-43), not a solid green rectangle.  
10. Read Apple **Adopting Liquid Glass** + **SwiftUI** technology overviews; apply **LG-A1–LG-A12** / **AR-5** (SwiftUI only).

### Do not

1. Ask the agent to “make it look Apple” without HTML + tokens.  
2. Let the agent hardcode hex outside the token table.  
3. Use multi-brand colors on meters.  
4. Treat HTML as copy-paste Swift — it is **structure + tokens + IA**, not AppKit API.  
5. Clip provider strip or detail scroll with a hard rectangular mask and no edge dissolve.

## Token map (HTML → Swift)

| CSS (dark) | Meaning | Swift direction |
|---|---|---|
| `--jk` `#5cf07a` | Phosphor accent | Brand accent / selection / high status |
| `--jk` light `#0b774e` | Accent on light | Same role, AA |
| `--status-high/mid/low` | Meter + % | Map remaining % bands |
| `--label / --secondary / --tertiary` | Type hierarchy | `.primary` / `.secondary` / `.tertiary` |
| `--glass` | Popover chrome | `GlassFallbacks.panelSurfaceBackground` |
| `--glass-inset` | Content cards | `contentCardBackground` / secondary fill |
| 8 / 12 / 14 / 16 / 20 | Spacing | Layout constants |
| SF stack | Type | System SF Pro |
| Mono digits | Metrics | `monospacedDigit` / SF Mono |

## Credential source (product rule)

UI shows **only** the **exact** Rust `credential_origin` string for the winning resolver arm, e.g.:

- `OAuth · ~/.codex/auth.json`
- `OAuth · macOS Keychain (Claude Code-credentials)`
- `API key · env AMP_API_KEY`
- `API token · env ZAI_API_KEY`

Never “file or env” disjunctions.  
**Never** in-app “how jackin resolved it” / resolver narrative — that is documentation only.

## Popover IA (locked)

```text
Overview  → provider groups → per-account weekly summary (no provider strip)
Providers → centered H-scroll provider strip → left H-scroll accounts
          → full bucket template per provider (Capsule parity)
Status bar → transparent dual stack, template logos
```

## Usage window (next design track)

Same tokens, IA, auth, reset separation, multi-account sidebar. New HTML section when operator opens that track.

## Predictability checklist for implementer PR

- [ ] Matches HTML dark + light screenshots  
- [ ] Tokens only (no rogue hex)  
- [ ] Status high/mid/low only on meters  
- [ ] Credential source = Rust string  
- [ ] Reset line separate from pace  
- [ ] Provider strip centered; accounts left  
- [ ] Official logos when assets land  
