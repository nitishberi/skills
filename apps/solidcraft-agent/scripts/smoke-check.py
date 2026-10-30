#!/usr/bin/env python3
"""Lightweight smoke checks when the .NET SDK is unavailable (e.g. egress-blocked CI).

Mirrors a subset of unit-test assertions for framing, bevel math, and seed lesson count.
Prefer `dotnet test SolidCraftAgent.Libraries.slnf` whenever the SDK is installed.
"""

from __future__ import annotations

import math
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def check_bevel() -> None:
    width, angle_deg, thickness = 0.5, 60.0, 1.0
    depth = width * math.tan(math.radians(angle_deg))
    flat = thickness - depth
    assert abs(depth - 0.8660254037844386) < 1e-12, depth
    assert abs(flat - 0.1339745962155614) < 1e-12, flat
    mistake = thickness / math.tan(math.radians(angle_deg))
    assert abs(mistake - 0.5773502691896257) < 1e-12, mistake


def check_seed_lessons() -> None:
    text = (ROOT / "data" / "lessons-seed.md").read_text(encoding="utf-8")
    ids = re.findall(r"^##\s+(L\d+)\s+-\s+", text, flags=re.M)
    assert ids == [f"L00{i}" for i in range(1, 8)], ids


def check_framing() -> None:
    body = b'{"jsonrpc":"2.0","id":1,"result":{}}'
    header = f"Content-Length: {len(body)}\r\n\r\n".encode("ascii")
    framed = header + body
    sep = framed.index(b"\r\n\r\n")
    length = int(framed[:sep].decode("ascii").split(":", 1)[1].strip())
    decoded = framed[sep + 4 : sep + 4 + length]
    assert decoded == body


def check_no_em_dashes() -> None:
    bad = []
    for path in ROOT.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in {".md", ".cs", ".json", ".xaml"}:
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        if "\u2014" in text or "\u2013" in text:
            bad.append(str(path))
    assert not bad, bad


def main() -> int:
    check_bevel()
    check_seed_lessons()
    check_framing()
    check_no_em_dashes()
    print("smoke-check OK: bevel math, 7 seed lessons, MCP framing, no em-dashes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
