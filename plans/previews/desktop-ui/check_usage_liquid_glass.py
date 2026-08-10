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
    # Anti-dupe: do not ship both metric-row and bucket heroes in usage views
    usage = html.split('id="usage"', 1)[-1].split('id="glass"', 1)[0]
    need("metric-row" not in usage or "bucket" not in usage, "usage still has metric-row + bucket dual story")
    need("usage-crumb" not in usage, "titlebar crumb re-stating content title must be removed")
    # One continuous surface: content fills .win; glass chrome floats on top.
    need(
        re.search(r"\.win\s*\{[^}]*background:\s*var\(--content-bg\)", html, re.S) is not None
        or "background: var(--content-bg)" in html,
        "usage window must be one solid content canvas",
    )
    need(
        re.search(r"\.win\s+\.side\s*\{[^}]*position:\s*absolute", html, re.S) is not None,
        "sidebar must float (position absolute) over content",
    )
    need("nav-provider" in html, "provider nav system missing")
    need("nav-acct" in html, "account nav system missing")
    need("acct-rail" in html, "account rail container missing")
    # Glance progress on accounts, not providers.
    need("a-meter" in html, "account mini-meter (glance progress) missing")
    need(
        re.search(r"\.win\s+\.nav-provider\s+\.p-meter", html) is None
        and 'class="p-meter' not in html
        and "p-trail" not in html.split('id="usage"', 1)[-1].split('id="glass"', 1)[0],
        "provider row must not show glance meter/trail (moved to accounts)",
    )
    # Account = secondary radio well (multi); no detail chip strip dupe.
    need(
        "a-radio" in html and ".nav-acct.on .a-radio" in html,
        "account radio selection indicator missing",
    )
    need(
        "acct-switch" not in html and "acct-chip" not in html,
        "detail account chip strip must stay removed (sidebar nest only)",
    )
    need(
        "border-left: 2.5px solid transparent" not in html,
        "AI-slop one-sided account border still present",
    )
    need(
        "2 accounts" in html,
        "multi-account provider caption missing",
    )
    need(
        re.search(
            r"\.win\s+\.nav-acct\.on\s*\{[^}]*border-color:\s*color-mix\(in srgb,\s*var\(--jk\)",
            html,
            re.S,
        )
        is None,
        "account must not use provider-style phosphor full-fill border selection",
    )
    need("chrome-float" in html, "floating chrome-float overlay missing")
    need(
        "tb-btn" in html and "backdrop-filter" in html,
        "Usage toolbar Refresh must be glass (tb-btn + backdrop-filter)",
    )
    need(
        'class="tb-btn primary"' not in html and ".tb-btn.primary" not in html,
        "solid primary Refresh slab must be removed (LG glass capsule only)",
    )
    need(
        "page-title" not in html.split('id="usage"', 1)[-1].split('id="glass"', 1)[0],
        "redundant Usage page-title near Refresh must stay removed",
    )
    need(".nav-provider.on" in html, "provider selection rule missing")
    need(".nav-acct.on" in html, "account selection rule missing")
    # Distinct systems: provider class ≠ account class; multi-account fixture present
    need(
        "nav-provider" in html and "nav-acct" in html and "nav-provider" != "nav-acct",
        "provider and account must use distinct classes",
    )
    need(
        'data-acct="a1"' in html and 'data-acct="a2"' in html,
        "OpenAI multi-account fixture keys a1/a2 missing",
    )
    need("57% left" in html, "Weekly remaining fixture '57% left' missing")
    need("list_accounts" in html, "list_accounts multi-account API mention missing from prototype")
    # Selected-account glance consistency: a1 Weekly 57%, a2 Weekly 0%
    need("openai:a1" in html and "openai:a2" in html, "per-account detail fixtures missing")
    need(
        re.search(r"openai:a1[\s\S]*?Weekly[\s\S]*?57% left", html) is not None,
        "a1 Weekly detail must show 57% left (matches glance)",
    )
    need(
        re.search(r"openai:a2[\s\S]*?Weekly[\s\S]*?0% left", html) is not None,
        "a2 Weekly detail must show 0% left (matches glance)",
    )
    need(
        "Session" in html and "Codex Spark 5-hour" in html and "Codex Spark Weekly" in html,
        "Codex full bucket order incomplete in fixture",
    )
    # 0% must be empty track — no fake minimum fill (Apple ProgressView).
    need(
        "width: 3% !important" not in html and "width:3% !important" not in html,
        "depleted meters must not force a 3% fake fill sliver",
    )
    need(
        re.search(r"depleted[^>]*>\s*<i[^>]*width:\s*3%", html) is None
        and 'style="width:3%"' not in html,
        "inline depleted meter width must be 0%, not 3%",
    )
    need(
        "width: 0% !important" in html or 'width:0%"' in html or "width:0%" in html,
        "0% empty-track meter mapping missing from prototype",
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
