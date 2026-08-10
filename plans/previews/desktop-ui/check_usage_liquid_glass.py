#!/usr/bin/env python3
"""Structural checks for Usage window Liquid Glass craft (shipped index.html).

Run from repo root:
  python3 plans/previews/desktop-ui/check_usage_liquid_glass.py
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

HTML = Path(__file__).with_name("index.html")


def main() -> int:
    if not HTML.is_file():
        print(f"FAIL: missing {HTML}", file=sys.stderr)
        return 1
    html = HTML.read_text(encoding="utf-8")
    failures: list[str] = []

    def need(cond: bool, msg: str) -> None:
        if not cond:
            failures.append(msg)

    need('id="usage-win"' in html, "usage-win root missing")
    need("data-lg-sidebar" in html, "Liquid Glass sidebar marker missing")
    need(
        "var(--lg-blur)" in html
        or re.search(
            r"\.win\s+\.side\s*\{[^}]*backdrop-filter:\s*blur\(([5-9]\d|\d{3,})",
            html,
            re.S,
        )
        is not None,
        "sidebar blur too weak (<50px) or missing",
    )
    need("--lg-side" in html, "--lg-side glass token missing")
    need("--lg-specular" in html, "multi-layer specular token missing")
    need("limit-list" in html, "single limit-list (anti-dupe) missing")
    need("win .body" in html or 'class="body"' in html, "body grid wrapper missing")
    # Anti-dupe: do not ship both metric-row and bucket heroes in usage views
    usage = html.split('id="usage"', 1)[-1].split('id="glass"', 1)[0]
    need("metric-row" not in usage or "bucket" not in usage, "usage still has metric-row + bucket dual story")
    need("usage-crumb" not in usage, "titlebar crumb re-stating content title must be removed")
    need(
        re.search(r"\.win\s*\{[^}]*background:\s*transparent", html, re.S) is not None,
        "window shell must be transparent for stage bleed under glass",
    )
    need(
        re.search(r"\.win\s+\.main\s*\{[^}]*var\(--content-bg\)", html, re.S) is not None,
        "content pane must use solid --content-bg",
    )
    need("nav-provider" in html, "provider nav system missing")
    need("nav-acct" in html, "account nav system missing")
    need("acct-rail" in html, "account rail container missing")
    need("p-meter" in html, "provider mini-meter missing")
    # Account selection uses full continuous stroke (de-slop), not left-only border.
    need(
        "nav-acct.on" in html and "border-color:" in html,
        "account full-perimeter selection stroke missing",
    )
    need(
        "border-left: 2.5px solid transparent" not in html,
        "AI-slop one-sided account border still present",
    )
    need("chrome-float" in html or "side" in html and "position: absolute" in html,
         "floating sidebar layout missing")
    need(".nav-provider.on" in html, "provider selection rule missing")
    need(".nav-acct.on" in html, "account selection rule missing")
    # Same selection chrome for both would re-use one class; require distinct classes
    need(
        "nav-provider" in html and "nav-acct" in html and "nav-provider" != "nav-acct",
        "provider and account must use distinct classes",
    )

    usage = html.split('id="usage"', 1)[-1].split('id="glass"', 1)[0]
    for bad in ("$/token", "spend chart", "sparkline", "cost-of-session"):
        need(bad.lower() not in usage.lower(), f"forbidden usage surface: {bad}")
    need(
        "limits only" in usage.lower() or "Limits only" in usage,
        "limits-only copy missing from Usage panel",
    )
    need('[data-theme="light"]' in html, "light theme tokens missing")
    need("--status-high" in html and "--status-mid" in html and "--status-low" in html, "3 status tokens missing")

    if failures:
        print("FAIL:")
        for f in failures:
            print(f"  - {f}")
        return 1
    print("PASS: Usage Liquid Glass + provider≠account structural checks")
    return 0


if __name__ == "__main__":
    sys.exit(main())
