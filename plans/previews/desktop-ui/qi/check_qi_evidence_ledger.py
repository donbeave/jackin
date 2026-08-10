#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Alexey Zhokhov
# SPDX-License-Identifier: Apache-2.0
"""Fail if QI prose cites missing PNG paths or ledger Pass rows lack files.

  python3 plans/previews/desktop-ui/qi/check_qi_evidence_ledger.py

No third-party TOML deps (stdlib only; works on macOS system Python 3.9).
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
LEDGER = ROOT / "advisor-plans" / "qi-artifacts" / "EVIDENCE_LEDGER.toml"
SNAPSHOT_HARNESS = (
    ROOT / "native" / "Tools" / "DesktopVisualSnapshotHarness" / "main.swift"
)
PROSE_GLOBS = [
    ROOT / "advisor-plans" / "VISUAL_QA_LOG.md",
    ROOT / "advisor-plans" / "qi-artifacts" / "parity-matrix.md",
]
PROSE_DIRS = [
    ROOT / "advisor-plans" / "qi-artifacts" / "deltas",
]

PNG_REF = re.compile(
    r"(?:advisor-plans/qi-artifacts/(?:html|native)/)?"
    r"([a-z0-9][a-z0-9._-]*\.png)",
    re.I,
)


def parse_ledger_scenes(text: str) -> list[dict]:
    """Minimal [[scene]] table parser for our ledger shape."""
    scenes: list[dict] = []
    current: dict | None = None
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line == "[[scene]]":
            if current is not None:
                scenes.append(current)
            current = {}
            continue
        if current is None:
            continue
        if "=" not in line:
            continue
        key, _, val = line.partition("=")
        key = key.strip()
        val = val.strip()
        if val.startswith('"') and val.endswith('"'):
            val = val[1:-1]
        current[key] = val
    if current is not None:
        scenes.append(current)
    return scenes


def fail(msg: str, failures: list[str]) -> None:
    failures.append(msg)
    print(f"FAIL  {msg}")


def check_ledger_rows(scenes: list[dict], failures: list[str]) -> None:
    for row in scenes:
        sid = f"{row.get('id')}·{row.get('theme')}"
        tier = row.get("capture_tier", "")
        verdict = row.get("verdict", "")
        native = row.get("native_path") or ""
        html = row.get("html_path") or ""
        note = row.get("blocked_note_path") or ""

        if verdict == "pass":
            if tier == "blocked":
                fail(f"{sid}: verdict=pass but capture_tier=blocked", failures)
            if not native:
                fail(f"{sid}: pass without native_path", failures)
            else:
                p = ROOT / native
                if not p.is_file():
                    fail(f"{sid}: missing native file {native}", failures)
            if html:
                p = ROOT / html
                if not p.is_file():
                    fail(f"{sid}: missing html file {html}", failures)

        if verdict == "blocked" or tier == "blocked":
            if note:
                p = ROOT / note
                if not p.is_file():
                    fail(f"{sid}: blocked_note_path missing {note}", failures)


def collect_prose_paths() -> list[Path]:
    paths = [p for p in PROSE_GLOBS if p.is_file()]
    for d in PROSE_DIRS:
        if d.is_dir():
            paths.extend(sorted(d.glob("*.md")))
    return paths


def check_prose_png_refs(failures: list[str]) -> None:
    native_dir = ROOT / "advisor-plans" / "qi-artifacts" / "native"
    html_dir = ROOT / "advisor-plans" / "qi-artifacts" / "html"
    for md in collect_prose_paths():
        text = md.read_text(encoding="utf-8")
        rel = md.relative_to(ROOT)

        # Stale live craft claim patterns (skeptic high)
        if re.search(r"live popover-live\b|popover-live-\*", text):
            fail(f"{rel}: cites deleted live popover-live-* craft", failures)
        if re.search(r"popover-live-openai|popover-live-anthropic", text):
            if "BLOCKED" not in text and "removed" not in text.lower() and "not used" not in text.lower():
                fail(
                    f"{rel}: cites popover-live-openai/anthropic without BLOCKED",
                    failures,
                )

        for m in PNG_REF.finditer(text):
            base = m.group(1)
            if "*" in base:
                continue
            in_native = (native_dir / base).is_file()
            in_html = (html_dir / base).is_file()
            blocked = (native_dir / base.replace(".png", ".BLOCKED.txt")).is_file()
            if base.startswith("popover-live") and (
                native_dir / "popover-live.BLOCKED.txt"
            ).is_file():
                blocked = True
            if base.startswith("ctx-menu") and (
                native_dir / "ctx-menu-live-dark.BLOCKED.txt"
            ).is_file():
                blocked = True
            if not in_native and not in_html and not blocked:
                fail(f"{rel}: references missing PNG {base}", failures)


def check_no_orphan_live_craft_files(scenes: list[dict], failures: list[str]) -> None:
    native = ROOT / "advisor-plans" / "qi-artifacts" / "native"
    ledgered_live_passes = {
        Path(row.get("native_path", "")).name
        for row in scenes
        if row.get("capture_tier") == "live" and row.get("verdict") == "pass"
    }
    for name in ("popover-live-openai-dark.png", "popover-live-anthropic-dark.png"):
        if (native / name).is_file() and name not in ledgered_live_passes:
            fail(
                f"orphan live craft PNG present ({name}); remove or re-ledger as live pass",
                failures,
            )


def check_window_capture_ownership(failures: list[str]) -> None:
    """Full-window evidence must target window ID, never screen coordinates."""
    if not SNAPSHOT_HARNESS.is_file():
        fail(f"missing snapshot harness {SNAPSHOT_HARNESS}", failures)
        return
    text = SNAPSHOT_HARNESS.read_text(encoding="utf-8")
    if 'proc.arguments = ["-x", "-R"' in text:
        fail("snapshot harness uses unsafe region capture; another app can occlude evidence", failures)
    if 'proc.arguments = ["-x", "-l"' not in text:
        fail("snapshot harness lacks window-ID screencapture", failures)


def main() -> int:
    if not LEDGER.is_file():
        print(f"FAIL  missing ledger {LEDGER}")
        return 1
    failures: list[str] = []
    scenes = parse_ledger_scenes(LEDGER.read_text(encoding="utf-8"))
    if not scenes:
        fail("ledger has zero [[scene]] rows", failures)
    check_ledger_rows(scenes, failures)
    check_prose_png_refs(failures)
    check_no_orphan_live_craft_files(scenes, failures)
    check_window_capture_ownership(failures)

    if failures:
        print(f"---\nQI evidence ledger: {len(failures)} FAILURE(S)")
        return 1
    passed = sum(1 for s in scenes if s.get("verdict") == "pass")
    blocked = sum(1 for s in scenes if s.get("verdict") == "blocked")
    print(
        f"PASS: QI evidence ledger — {passed} pass rows, {blocked} blocked, "
        f"prose PNG refs consistent"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
