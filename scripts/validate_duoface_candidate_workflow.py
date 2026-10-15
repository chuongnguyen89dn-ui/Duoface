#!/usr/bin/env python3
"""Strict NO-PACKAGE preflight of the manual DuoFace rootless candidate.

Read-only checks: hashes, candidate path/version, original package identity,
manual-only GitHub workflow structure, bash syntax, embedded Python syntax.
Does NOT invoke dpkg-deb --build, Theos, ldid, a deployment or Sileo.
"""
from __future__ import annotations

import ast
import hashlib
import json
import re
import struct
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WF = ROOT / ".github/workflows/duoface-approved-border-deb.yml"
SOURCE = ROOT / "runtime/fullscreen/DFPickerZoomMenu.xm"
BASE = ROOT / "dist/candidates/menu-zoom2/com.duonavi.app_1.0.3-12_menu-zoom2_iphoneos-arm64.deb"
BASE_SUMS = ROOT / "dist/candidates/menu-zoom2/SHA256SUMS.txt"
ALPHA = ROOT / "dist/visual-1.0.3-12/assets/duoface-logo-picker-alpha-v2.png"
ORIGINAL = ROOT / "dist/visual-1.0.3-12/assets/duoface-logo.png"
CANDIDATE = ROOT / "dist/candidates/menu-inline-live1/com.duonavi.app_1.0.3-12_menu-inline-live1_iphoneos-arm64.deb"

BASE_SHA = "0a44524456caa6a530fd1e605020f592e79500738de643a59ef0ff8e02296ad4"
ALPHA_SHA = "43b6dafb8fc0550c2b3032c11acae1e0712350ca5b4dd235b7dc14c7951c74f7"
ORIGINAL_SHA = "78450d8ee4759353bdc21f27a06016c03fab61038ae60109ba21515c087b0089"


def sha(path: Path) -> str:
    assert path.is_file(), f"Missing source input: {path}"
    return hashlib.sha256(path.read_bytes()).hexdigest()


def verify() -> dict:
    wf = WF.read_text()
    source = SOURCE.read_text()
    assert "\n  workflow_dispatch:\n" in wf, "Workflow must be manually runnable"
    assert "\n  workflow_call:\n" in wf, "Existing reusable entry point must remain"
    assert not re.search(r"(?m)^\s+push:\s*$", wf), "Packaging must NOT trigger on push"
    assert not re.search(r"(?m)^\s+schedule:\s*$", wf), "Packaging must NOT run on a schedule"
    assert not re.search(r"(?mi)^\s*(gh release|reprepro|aptly|sileo publish)\b", wf), "No Sileo publication commands allowed"
    assert "menu-compact1" not in wf, "Do not reuse earlier candidate name"
    assert str(CANDIDATE.relative_to(ROOT)) in wf, "Unique candidate path missing"
    assert "Version: 1.0.3-12+menu-inline-live1" in wf, "Candidate version guard missing"
    assert "'com.duonavi.app'" in wf, "Do not alter original bundle/package identity"
    assert not CANDIDATE.exists(), "Candidate output already exists; do not overwrite"

    for name in (
        "DFRestyleOneRecentAppRow", "DFRestyleNativeRecentAppRows",
        "DFRestyleRecentClearAll", "DFBuildingNativeRecentRows",
        "DFClearNativePickerChrome", "DFNativeSingleAppAction",
        "DFNativeCloseAllAction", "DFPickerApprovedHeaderLogo",
        "OVERLAY_RUNNING_TAG", "OVERLAY_PID_TAG", "OVERLAY_BACKGROUND_TAG",
        "arrow.clockwise", "xmark.circle", "duoface-logo-picker-alpha-v2.png",
        "restartSingleAppTapped:", "closeSingleAppTapped:", "closeAllBridgedAppsTapped:",
    ):
        assert name in source, f"Current source missing {name}"
    assert "NSString *zoomTitle=@\"Zoom\"" in source
    assert "DFDecorate(close,@\"Close\"" in source
    assert "DFDecorate(clearAll,@\"Clear All\"" in source
    assert "#E3020F" in source
    assert "DFBuildingNativeRecentRows=YES" in source
    assert "DFBuildingNativeRecentRows=wasBuilding" in source

    actual_base = sha(BASE)
    assert actual_base == BASE_SHA, "Base DEB checksum mismatch"
    assert BASE_SHA in BASE_SUMS.read_text(), "Base checksum report mismatch"
    actual_alpha = sha(ALPHA)
    assert actual_alpha == ALPHA_SHA, "Approved alpha-v2 asset checksum mismatch"
    assert sha(ORIGINAL) == ORIGINAL_SHA, "Original approved logo has changed"
    data = ALPHA.read_bytes()
    assert data[:8] == bytes.fromhex("89504e470d0a1a0a"), "Alpha logo is not PNG"
    assert struct.unpack(">II", data[16:24]) == (627, 228), "Wrong alpha-v2 dimensions"
    assert data[24] == 8 and data[25] == 6, "Expected 8-bit RGBA logo"

    # Each YAML run block uses 10-space-indented commands after "run: |".
    # Strip that shell block's indentation and check without EXECUTING anything.
    lines = wf.splitlines(keepends=True)
    shell_blocks = []
    for i, line in enumerate(lines):
        if not re.match(r"^ {8}run: \|\s*$", line):
            continue
        cmds = []
        for body in lines[i + 1 :]:
            if body.strip() and not body.startswith(" " * 10):
                break
            cmds.append(body[10:] if body.startswith(" " * 10) else body)
        shell_blocks.append("".join(cmds))
    assert len(shell_blocks) >= 5, f"Expected packaging shell steps; got {len(shell_blocks)}"
    python_blocks = []
    for block in shell_blocks:
        bash = subprocess.run(["bash", "-n"], input=block, text=True, capture_output=True)
        assert bash.returncode == 0, f"Bad packaging Bash syntax: {bash.stderr}"
        snippets = re.findall(r"(?ms)^python3 - <<'PY'\n(.*?)^PY$", block)
        python_blocks.extend(snippets)
    assert len(python_blocks) == 2, f"Expected two embedded Python audit snippets, got {len(python_blocks)}"
    for idx, snippet in enumerate(python_blocks, 1):
        try:
            ast.parse(snippet, filename=f"packaging-snippet-{idx}")
        except SyntaxError as exc:
            raise AssertionError(f"Packaging Python #{idx}: {exc}") from exc

    for token in (
        "ldid -S artifacts/DuoFaceFullscreenBridge.dylib",
        "ldid -S artifacts/DuoFaceVisualHook.dylib",
        "DuoFaceFullscreenBridge.plist",
        "DuoFaceVisualHook.plist",
        "dpkg-deb -R \"$BASE\"", "dpkg-deb --build --root-owner-group",
        "dpkg-deb -x \"$OUT\" \"$EXTRACT\"",
        "BUILD_AUDIT.json", "CONTENTS.txt", "SHA256SUMS.txt",
        "sileo_published",
        "menu-inline-live1",
        ALPHA_SHA, ORIGINAL_SHA,
        "bc1df854ec7a2ddfeec4cb81b080ead34b54df80143d4a8f6254bb8b618003ce",
    ):
        assert token in wf, f"Missing packaging safeguard: {token}"
    bad_json_newline = "report.write_text(json.dumps(data,indent=2,ensure_ascii=False)+'" + chr(92)*2 + "n')"
    good_json_newline = "report.write_text(json.dumps(data,indent=2,ensure_ascii=False)+'" + chr(92) + "n')"
    assert bad_json_newline not in wf, "JSON report newline incorrectly escaped"
    assert good_json_newline in wf, "JSON report line missing or malformed"
    return {
        "status": "PREFLIGHT_PASS_MANUAL_DEB_NOT_BUILT",
        "candidate": str(CANDIDATE.relative_to(ROOT)),
        "base_sha256": actual_base,
        "alpha_logo_sha256": actual_alpha,
        "original_logo_sha256": ORIGINAL_SHA,
        "shell_steps_syntax_checked": len(shell_blocks),
        "python_blocks_syntax_checked": len(python_blocks),
        "package_built": False,
        "sileo_published": False,
    }


if __name__ == "__main__":
    print(json.dumps(verify(), indent=2, ensure_ascii=False))
