# macOS system chrome — jackin❯ desktop craft

How status interactions and the Usage window sit on a **real Mac display**.
HTML stages under `index.html` must look like this — not like a web panel with a fake bar.

## Official references

| Topic | URL |
|---|---|
| **The menu bar** (HIG) | https://developer.apple.com/design/human-interface-guidelines/the-menu-bar |
| **Menus** (HIG) | https://developer.apple.com/design/human-interface-guidelines/menus |
| **Toolbars** (HIG) | https://developer.apple.com/design/human-interface-guidelines/toolbars |
| **NSStatusItem** | https://developer.apple.com/documentation/appkit/nsstatusitem |
| **Liquid Glass** | https://developer.apple.com/documentation/technologyoverviews/liquid-glass |
| **Adopting Liquid Glass** | https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass |
| Menu bar customization (Tahoe) | https://support.apple.com/guide/mac-help/customize-the-menu-bar-mchl4af84660/mac |

## System menu bar anatomy (left → right)

```
┌──────────────────────────────────────────────────────────────────────────┐
│   [App menus when frontmost]                    [extras…]  CC  ⏰ clock │
└──────────────────────────────────────────────────────────────────────────┘
```

| Zone | Contents | jackin❯ desktop |
|---|---|---|
| **Leading — Apple menu** | Always first | Always show  in craft mocks |
| **Leading — app menus** | App name · File · Edit · View · Window · Help | Only when activation is **`.regular`** (Usage/Settings open): **jackin❯ desktop · Edit · View · Window** |
| **Trailing — menu bar extras** | App `NSStatusItem`s, then system extras | Our dual-stack status items (template mono) |
| **Trailing — system** | Control Center, clock, optional Notification Center | Show Control Center + clock as **layout references** (not our chrome) |

### Two activation modes

| Mode | When | Menu bar | Dock |
|---|---|---|---|
| **`.accessory`** | Status-only agent |  only leading; **our extras** trailing; **no** app menus | Hidden |
| **`.regular`** | Usage or Settings key window |  · **jackin❯ desktop** · Edit · View · Window · extras still trailing | Visible |

Native: `AppActivation.presentWindows()` / `resignToAccessoryIfNeeded()`.

## Status items (menu bar extras)

- Live in the **system** menu bar — not inside a window, not a custom toolbar panel.
- **Template mono** icons + dual stack (compact reset / glance %). **No Liquid Glass chips** on the bar (LG-A1 / FB1-6).
- Left-click → `NSPopover` under the item (glass shell for the popover panel only).
- Right-click → context menu (glass).
- Real apps to compare: battery, Wi‑Fi, Control Center density; third-party extras (Bartender, iStat, etc.) for dual-line density — still template mono.

## Usage window (app window chrome)

HIG **Toolbars**: toolbar lives in the **window frame** (titlebar unified), not as a floating web strip.

| Layer | Craft |
|---|---|
| System menu bar | Still full screen top; app menus while regular |
| Window | Separate surface on desktop below the menu bar |
| Titlebar + NSToolbar | Unified: traffic · centered title · trailing toolbar items (Refresh) |
| Content | NavigationSplitView glass sidebar + solid detail (LG nav vs content) |

**Wrong:** drawing a menu bar as a rounded pill *above* the window.  
**Right:** menu bar is the **display edge**; window is a separate rectangle on the wallpaper.

Native: `NSHostingController` + `window.toolbarStyle = .unified` so SwiftUI `.toolbar` is a real **NSToolbar**.

## Liquid Glass interaction rules

| Surface | Material |
|---|---|
| System menu bar | System transparent / LG (Tahoe) — **do not restyle** |
| Status item glyphs | Template mono |
| Glance popover | Regular glass panel (`GlassFallbacks.panelSurfaceBackground`) |
| Usage sidebar / toolbar | System glass nav (LG-A1) |
| Usage limit lists | Content layer — **not** glass (LG-A2) |

## HTML SoT mapping

| Scene | `index.html` |
|---|---|
| Status interactions | `#flow` → `.desktop[data-activation=accessory]` |
| Usage window | `#usage` → `.desktop[data-activation=regular]` + `.win` |
| Markers | `data-desktop-scene`, `data-sys-menubar`, `data-status-toolbar` |

## Implementer checklist

- [ ] Status items only via `NSStatusBar.system` / `NSStatusItem`
- [ ] No custom “menu bar” view inside the Usage window content
- [ ] Open window → `.regular` + main menu; close last window → `.accessory`
- [ ] Usage toolbar via hosting controller + unified NSToolbar
- [ ] Popover anchors to status item button (not arbitrary screen coords)
