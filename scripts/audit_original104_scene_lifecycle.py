#!/usr/bin/env python3
"""Extract raw, read-only lifecycle evidence from original DuoNavi 1.0.4."""
from __future__ import annotations

import argparse
import hashlib
import re
from pathlib import Path

PATTERN = re.compile(
    r"CBBridgedUIAppView|CBBridgedSplitApp|CBWindow|destroyWindows|"
    r"setRequestedMode:|_setCurrentMode:|invalidate|"
    r"updateSettings:withTransitionContext:completion:|"
    r"removeFromParentViewController|beginAppearanceTransition",
    re.I,
)


def read(path: Path, limit: int = 18_000_000) -> str:
    return path.read_text(encoding="utf-8", errors="replace")[:limit] if path.is_file() else ""


def checksum(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1048576), b""):
            h.update(block)
    return h.hexdigest()


def context(text: str, radius: int, max_hits: int, cap: int) -> tuple[str, int]:
    lines = text.splitlines()
    matched = [i for i, line in enumerate(lines) if PATTERN.search(line)]
    selected = set()
    for pos in matched[:max_hits]:
        selected.update(range(max(0, pos-radius), min(len(lines), pos+radius+1)))
    chunks, previous = [], -2
    for i in sorted(selected):
        if i > previous+1:
            chunks.append("\n... context gap ...\n")
        chunks.append(f"{i+1:>7} | {lines[i]}\n")
        previous = i
    result = "".join(chunks)
    if len(result) > cap:
        result = result[:cap] + "\n[TRUNCATED]\n"
    return result or "[NO_MATCH_IN_OUTPUT]\n", len(matched)


def main() -> int:
    parser = argparse.ArgumentParser()
    for name in ("deb", "binary", "raw", "out"):
        parser.add_argument("--"+name, type=Path, required=True)
    parser.add_argument("--commit", required=True)
    args = parser.parse_args()
    body = [
        "# Original DuoNavi 1.0.4 scene lifecycle static evidence",
        "",
        "Source commit: " + args.commit,
        f"DEB: {args.deb} sha256={checksum(args.deb)}",
        f"Mach-O: {args.binary} sha256={checksum(args.binary)}",
        "",
        "STATIC ONLY. No claim about runtime call order, ownership, "
        "actual deallocation sequence, or device-test outcome. "
        "Selectors and symbols are leads for disassembly, not proof.",
        "",
    ]
    specs = [
        ("control.txt", "Package control", 0, 0, 12000),
        ("files.txt", "Package paths", 0, 0, 24000),
        ("install-scripts.txt", "Maintainer scripts", 0, 0, 16000),
        ("libraries.txt", "Dynamic dependencies", 0, 0, 12000),
        ("symbols.txt", "nm target symbols", 3, 120, 24000),
        ("strings.txt", "Target strings", 1, 150, 18000),
        ("objc.txt", "otool Objective-C metadata", 14, 140, 90000),
        ("llvm-objc.txt", "LLVM Objective-C metadata", 10, 120, 90000),
        ("disasm.txt", "LLVM disassembly contexts", 25, 80, 100000),
    ]
    for filename, heading, radius, hits, cap in specs:
        raw = read(args.raw / filename)
        if radius:
            snippet, matches = context(raw, radius, hits, cap)
        else:
            snippet, matches = raw[:cap] or "[UNAVAILABLE]", 0
        body += ["## " + heading, f"Source file: {filename}; matches={matches}",
                 "", "~~~text", snippet.rstrip(), "~~~", ""]
    body += [
        "## Next analysis gate", "",
        "Identify exact original 1.0.4 method IMPs from ObjC metadata; "
        "inspect disassembly and call ownership; compare with "
        "DFV12SceneHost close, DFCarPlaySplitCoordinator stop, QA shutdown. "
        "Do not modify Native12/Hub8. This report is not a build or a fix.", "",
    ]
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text("\n".join(body), encoding="utf-8")
    print(f"REPORT={args.out} bytes={args.out.stat().st_size}")
    for fn in ("objc.txt", "llvm-objc.txt", "disasm.txt"):
        raw = read(args.raw / fn)
        print(f"SOURCE={fn} chars={len(raw)} matches={len(PATTERN.findall(raw))}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
