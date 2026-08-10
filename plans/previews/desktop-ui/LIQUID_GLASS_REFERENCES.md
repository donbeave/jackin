# Liquid Glass references → jackin❯ desktop

Research snapshot for Usage window / popover craft. HTML is a **proxy** (blur + layered translucency), not AppKit `glassEffect` physics.

## What Liquid Glass *is* (Apple)

- **Navigation / control layer** only — bars, sidebars, toolbars, sheets, menus, popovers.  
- Content stays **solid / readable** so data does not fight refraction.  
- Material **reflects + refracts** surroundings; adapts light/dark; works with **scroll edge effects**.  
- Larger chrome (sidebars) picks up **ambient color** from app content + wallpaper.  
- System auto-applies to Toolbar / Sidebar / Menu bar on macOS Tahoe when built with current SDKs.

Sources: Apple Newsroom WWDC25, HIG Materials, WWDC25 “Meet Liquid Glass”.

## Third-party apps that went Liquid Glass

### Telegram (iOS full LG ~Jan 2026; Android follow-up; custom LG even pre–iOS 26)

| Pattern | What they did | Borrow for jackin❯ |
|---|---|---|
| Frosted chrome everywhere that navigates | Nav bars, panels, overlays translucent | Usage **sidebar + titlebar + toolbar capsules** |
| Panel-in-panel depth | Glass list sitting inside a frosted well | **`.side-well`** floating list container |
| Luminous selection | Selected row feels lit, soft edge | Provider **glass pill** + soft phosphor glow |
| Nested secondary lists | Quieter nested chrome vs primary rows | **Account rail** nested, different selection |
| Capsule controls | Rounded glass buttons | **`.tb-btn`** pill + specular gradient |
| Optional reduce | Power-saving toggle for effects | Native: Reduce Transparency / Motion via `GlassFallbacks` |
| Content still primary | Chat content remains readable | **Solid `.main`** content pane |

Telegram is *not* a pixel target — it proves **layered glass chrome + solid content** can feel “liquid” while staying usable.

### Apple first-party (Tahoe / iOS 26)

| App / surface | Pattern | Borrow |
|---|---|---|
| **Finder** | Glass sidebar, ambient bleed, solid file content | Sidebar material, traffic lights continuity |
| **Safari** | Glass toolbar, content scrolls under | Soft scroll edges under titlebar |
| **Reminders / Music / Photos** | Translucent toolbars over solid lists | Titlebar-main glass strip over content |
| **Apple TV / system sidebars** | Sidebar refracts environment | Transparent window shell + stage bleed |
| **Control Center / menus** | Capsule glass controls | Toolbar / CTA capsules |

### Other noted third-party

| App | Note |
|---|---|
| **Pixelmator Pro** | Glass toolbars that stay **quiet** so canvas stays primary — same rule: chrome glass, content focus |
| **Surge Dashboard** (prior craft bar) | Native utility density, metric tiles, split chrome — quality bar for **IA**, not LG physics |

## Patterns we apply in HTML craft

1. **Transparent window shell** — stage wallpaper bleeds under glass (blur has something to refract).  
2. **Multi-layer glass** — specular gradient + mid fill + hairline + outer lift shadow.  
3. **Floating `.side-well`** — list lives in an inner frosted panel (Telegram depth).  
4. **Provider ≠ account** — primary luminous capsule vs nested left-accent rail (FB1-48).  
5. **Solid content pane** — metrics/groups remain content-layer (elevated inset, not full LG).  
6. **Capsule toolbar actions** — liquid pill controls with hover lift.  
7. **jackin accent restraint** — phosphor only on selection / high status / j❯, never full green glass.

## Native map (when Swift ships)

| HTML proxy | Native |
|---|---|
| `backdrop-filter: blur() saturate()` | `GlassFallbacks` / system glass materials |
| Soft scroller mask fades | `scrollEdgeEffect(.soft)` |
| Transparent shell + solid main | NSSplitView / NavigationSplitView materials |
| Capsule glass buttons | Glass button styles / `.borderedProminent` careful mapping |
| Reduce glass | Reduce Transparency → ultraThinMaterial fallback |

## Out of scope / do not copy

- Telegram AI / chat chrome, bottom tab bars on macOS Usage window.  
- Spend charts, cost sparklines, glass *on* dense data tables.  
- Full-window green phosphor glass (fights HIG + legibility).
