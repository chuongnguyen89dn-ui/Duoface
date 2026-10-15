#!/usr/bin/env python3
"""Static assertions for 0.30s logo drag; NOT an iPhone/CarPlay runtime test.

No DEB produced or modified. Reproducible: python3 scripts/check_duoface_grip_routes.py
"""
from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HOOK = ROOT / "src/DuoFaceVisualHook.m"
GRIP = ROOT / "src/DFDividerLogoGrip.inc"
BINARY_AUDIT = ROOT / "audit/divider/GRIP_MOBILITY_NATIVE6.json"
OUT = ROOT / "audit/divider/GRIP_GESTURE_SOURCE_ONLY_QA.json"


def body(source: str, signature: str) -> str:
    """Extract balanced C function body to avoid whole-file false positives."""
    start = source.index(signature)
    brace = source.index("{", start)
    depth = 0
    for index in range(brace, len(source)):
        if source[index] == "{":
            depth += 1
        elif source[index] == "}":
            depth -= 1
            if depth == 0:
                return source[brace:index + 1]
    raise AssertionError(f"unbalanced function {signature}")


def check() -> dict:
    hook = HOOK.read_text(encoding="utf-8")
    grip = GRIP.read_text(encoding="utf-8")
    audit = json.loads(BINARY_AUDIT.read_text(encoding="utf-8"))

    assert audit["press_config"]["minimum_press_duration_seconds"] == 0.4
    assert audit["press_config"]["touch_up_callback_selector"] == "onSwap"
    assert audit["press_config"]["long_press_callback_selector"] == "onRotate"
    assert audit["classes"]["CBDividerView"]["ivars"][1]["name"] == "_isBlinking"
    assert audit["hit_testing"]["detected_ivar_offset"] == 9

    # New source-only behavior does not modify the pinned native6 baseline.
    assert re.search(r"kDFLogoHoldThreshold\s*=\s*0\.30\s*;", grip)
    assert '#include "DFDividerLogoGrip.inc"' in hook
    assert "DFInstallLogoGripHooks(hook, divider)" in hook
    assert "DFLogoSetNativeHoldThreshold((UIButton *)button)" in hook
    assert "DFLogoRestorePositionBeforeLayout(self)" in hook
    assert "DFLogoSetRelativePos(info, fraction)" in grip
    assert "@selector(updateGripLayout)" in grip
    assert "splitRatio" not in grip.replace(
        "the divider pan must NOT adjust splitRatio", "")
    assert "setSplitRatio:" not in grip

    touchup = body(grip, "static void DFLogoGripUp(")
    assert "session->holdRecognized || session->panOnLogoMoved" in touchup
    assert "oldDFGripTouchCancel" in touchup
    assert "oldDFGripTouchUp" in touchup

    longhold = body(grip, "static void DFLogoGripHold(")
    assert "UIGestureRecognizerStateBegan" in longhold
    assert "session->holdRecognized=YES" in longhold
    assert "UIGestureRecognizerStateChanged" in longhold
    assert "DFLogoMoveWithHold" in longhold
    # Any fallback original onRotate must only run for non-logo recognizers.
    original_call = longhold.index("oldDFGripLongPress")
    guard = longhold.index("!DFLogoIsButton(divider, button)")
    first_return = longhold.index("return;")
    assert guard < original_call < first_return
    assert "oldDFGripLongPress" not in longhold[first_return:]

    pan = body(grip, "static void DFLogoDividerPan(")
    assert "session->logoTouchActive && session->pressed" in pan
    assert "BOOL swallow=session->dividerPanOwned;" in pan
    assert re.search(
        r"if\s*\(!swallow\)\s*\(\(void\s*\(\*\)\(id, SEL, id\)\)"
        r"oldDFGripDividerPan\)", pan)
    assert "session->panOnLogoMoved=YES" in pan

    down = body(grip, "static void DFLogoGripDown(")
    assert "session->logoTouchActive=YES" in down
    assert "session->holdRecognized=NO" in down
    assert "oldDFGripTouchDown" in down
    native_hook_install = body(grip, "static BOOL DFInstallLogoGripHooks(")
    for selector in ["moveButtonTouchDown:", "moveButtonTouchUp:",
                     "moveButtonTouchCancelled:", "handleMoveButtonLongPress:",
                     "handlePan:"]:
        assert selector in native_hook_install

    # Control-flow contract, NOT a simulation of UIKit gesture arbitration.
    cases = [
        {"gesture": "button quick tap <0.30s",
         "expected": "original onSwap on native touchUp; no logo relocation"},
        {"gesture": "button stationary hold >=0.30s",
         "expected": "longhold began; no onRotate; no splitRatio"},
        {"gesture": "button long hold, move along divider",
         "expected": "changed updates relativePos and native updateGripLayout"},
        {"gesture": "button starts pan before 0.30s",
         "expected": "ratio pan guarded; no accidental touchUp swap after movement"},
        {"gesture": "pan begins outside logo",
         "expected": "native CBDividerView.handlePan remains unchanged"},
        {"gesture": "logo longhold released",
         "expected": "latched consumed state suppresses late onSwap"},
    ]
    return {
        "status": "PASS_STATIC_SOURCE_ROUTE_AUDIT_ONLY",
        "not_runtime_or_device_test": True,
        "not_package_or_sileo": True,
        "user_hold_threshold_seconds": 0.3,
        "original_hold_seconds": 0.4,
        "assertion_groups": [
            "pinned native6 binary evidence",
            "0.30s on the existing UILongPressGestureRecognizer",
            "native short-tap onSwap preserved",
            "native long-hold onRotate suppressed for swap logo",
            "logo drag uses relativePos and native updateGripLayout",
            "ratio pan only forwarded if touch was not on logo",
            "no splitRatio setter called by logo code",
            "source hook integrates methods on actual CBDividerView",
        ],
        "scenarios_as_code_contracts": cases,
        "source_hashes": {
            str(HOOK.relative_to(ROOT)):
                hashlib.sha256(HOOK.read_bytes()).hexdigest(),
            str(GRIP.relative_to(ROOT)):
                hashlib.sha256(GRIP.read_bytes()).hexdigest(),
            str(BINARY_AUDIT.relative_to(ROOT)):
                hashlib.sha256(BINARY_AUDIT.read_bytes()).hexdigest(),
        },
    }


if __name__ == "__main__":
    result = check()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(result, ensure_ascii=False, indent=2))
