#!/usr/bin/env python3
"""Post-process Godot Web export for GitHub Pages: base href, cache-bust PCK, build meta."""

from __future__ import annotations

import json
import os
import re
import pathlib
import sys


def _slice_js_object(text: str, prefix: str) -> tuple[int, int]:
    pos = text.find(prefix)
    if pos < 0:
        raise ValueError(f"{prefix!r} not found")
    i = pos + len(prefix)
    while i < len(text) and text[i].isspace():
        i += 1
    if i >= len(text) or text[i] != "{":
        raise ValueError("expected { after prefix")
    start = i
    depth = 0
    in_str = False
    str_ch = ""
    esc = False
    while i < len(text):
        ch = text[i]
        if in_str:
            if esc:
                esc = False
            elif ch == "\\":
                esc = True
            elif ch == str_ch:
                in_str = False
        else:
            if ch in "\"'":
                in_str = True
                str_ch = ch
            elif ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    return start, i + 1
        i += 1
    raise ValueError("unbalanced braces in GODOT_CONFIG")


def main() -> int:
    sha = os.environ.get("GITHUB_SHA", "")
    run_id = os.environ.get("GITHUB_RUN_ID", "0")
    if not sha or len(sha) < 7:
        print("GITHUB_SHA missing or too short", file=sys.stderr)
        return 1

    short = sha[:7]
    web = pathlib.Path("export/web")
    html_path = web / "index.html"
    old_pck = web / "index.pck"
    if not html_path.is_file():
        print("missing index.html", file=sys.stderr)
        return 1
    if not old_pck.is_file():
        print("missing index.pck", file=sys.stderr)
        return 1

    new_name = f"index.{short}.{run_id}.pck"
    new_pck = web / new_name
    if new_pck.exists():
        new_pck.unlink()
    old_pck.rename(new_pck)
    pck_size = new_pck.stat().st_size

    text = html_path.read_text(encoding="utf-8")

    repo = os.environ.get("GITHUB_REPOSITORY", "x/THE-BLOCK").split("/")[1]
    base_tag = f'<base href="/{repo}/">'
    if not re.search(r"<base\s", text, flags=re.I):
        text2, n = re.subn(
            r"(<head[^>]*>)",
            lambda m: m.group(1) + "\n    " + base_tag + "\n",
            text,
            count=1,
            flags=re.I,
        )
        if n != 1:
            print("Could not inject <base href>", file=sys.stderr)
            return 1
        text = text2

    start, end = _slice_js_object(text, "const GODOT_CONFIG = ")
    cfg = json.loads(text[start:end])
    sizes = dict(cfg.get("fileSizes") or {})
    wasm_key = "index.wasm"
    wasm_size = sizes.get(wasm_key)
    if wasm_size is None:
        for k, v in sizes.items():
            if str(k).endswith(".wasm"):
                wasm_key = k
                wasm_size = v
                break
    if wasm_size is None:
        print("Could not find wasm size in fileSizes", file=sys.stderr)
        return 1

    cfg["mainPack"] = new_name
    cfg["fileSizes"] = {new_name: pck_size, wasm_key: wasm_size}
    new_json = json.dumps(cfg, separators=(",", ":"))
    text = text[:start] + new_json + text[end:]

    text, n = re.subn(
        r'src="index\.js"',
        f'src="index.js?v={short}.{run_id}"',
        text,
        count=1,
    )
    if n != 1:
        print("Could not patch index.js script src", file=sys.stderr)
        return 1

    meta = f'    <meta name="the-block-build" content="{sha}">\n'
    if "the-block-build" not in text:
        text2, n2 = re.subn(
            r'(<meta\s+charset="utf-8"\s*>)',
            r"\1\n" + meta,
            text,
            count=1,
            flags=re.I,
        )
        if n2 != 1:
            text2, n2 = re.subn(r"(<head[^>]*>\s*\n)", r"\1" + meta, text, count=1, flags=re.I)
        text = text2

    html_path.write_text(text, encoding="utf-8")
    print(f"Post-export OK: mainPack={new_name} pck_bytes={pck_size}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
