#!/usr/bin/env python3
"""Read-only, evidence-bound original Native12 .89 parity gap inventory.

Input is the archived original ARM64 disassembly, previously unpacked by the
SHA-pinned DEB scanner. The companion CI gate also independently checks the
actual immutable DEB and the extracted DuoFaceDashboard.dylib SHA256.
No vendor executable/code is shipped to the independent runtime.
"""
import argparse
import hashlib
import json
from pathlib import Path

EXPECTED_DEB = "2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad"
EXPECTED_IMAGE = "9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea"
SELECTORS = {
    "UIViewController": ["supportedInterfaceOrientations", "__supportedInterfaceOrientations"],
    "UIWindow": ["setFrame:", "setBounds:", "_setRotatableViewOrientation:duration:force:",
                 "sendEvent:", "_rotateWindowToOrientation:updateStatusBar:duration:skipCallbacks:"],
    "UIApplication": ["applicationState", "statusBarOrientation", "isIdleTimerDisabled",
                      "setIdleTimerDisabled:"],
    "UIWindowScene": ["interfaceOrientation", "_isSuspended", "_isDeactivated"],
    "UIDevice": ["orientation", "setOrientation:animated:", "setOrientation:"],
    "UIScreen": ["_userInterfaceIdiom", "bounds", "nativeBounds", "_referenceBounds"],
    "UIScreenMode": ["size"],
}
EXPECTED_ALL_KNOWN = sum(map(len, SELECTORS.values()))


def sha(data):
    return hashlib.sha256(data).hexdigest()


def inspect(archive, src, deb, dashboard):
    if archive["original_deb_sha256"] != EXPECTED_DEB:
        raise RuntimeError("original ARM64 record is not SHA-pinned")
    if archive["dashboard_image_sha256"] != EXPECTED_IMAGE:
        raise RuntimeError("original Dashboard image record has unexpected SHA")
    if sha(deb.read_bytes()) != EXPECTED_DEB or sha(dashboard.read_bytes()) != EXPECTED_IMAGE:
        raise RuntimeError("real original DEB or Dashboard binary does not match pins")
    code = archive["functions"]["app_scene_UIKit_orientation_reconciler"]
    if code["actual_function_start"] != "0x2ac688":
        raise RuntimeError("original hook installer entry is not exact")
    original = code["original_arm64"]
    hooks = []
    current_class = None
    class_pending = None
    latest_selector = None
    for instr in original:
        pc, asm = instr["pc"], instr["asm"]
        if "literal pool for: \"" in asm:
            literal = asm.split('literal pool for: "', 1)[1].split('"', 1)[0]
            if literal in SELECTORS or literal in ("AVPlayer", "AVPlayerItem", "NSDistributedNotificationCenter"):
                class_pending = literal
        if "_objc_getClass" in asm and class_pending:
            current_class = class_pending
            class_pending = None
        if "Objc selector ref:" in asm:
            latest_selector = asm.split("Objc selector ref: ", 1)[1]
        if "_MSHookMessageEx" in asm and (asm.lstrip().startswith(("bl ", "b "))):
            hooks.append({"pc": pc, "class": current_class,
                          "selector": latest_selector,
                          "installer": "MSHookMessageEx"})
    if len(hooks) < 33:
        raise RuntimeError(f"Expected multi-framework original hook installer; got {len(hooks)}")
    exact = {(h["class"], h["selector"]): h["pc"] for h in hooks}
    missing = [(cls, sel) for cls, sels in SELECTORS.items()
               for sel in sels if (cls, sel) not in exact]
    if missing:
        raise RuntimeError("Original hook grouping doesn't match raw ARM64: " + str(missing))
    relay = (src / "sideplay/duoface-native-scene-host/DFYouTubeOrientationRelay.m").read_text()
    host = (src / "sideplay/duoface-native-scene-host/DFSceneHost.m").read_text()
    if "requestGeometryUpdateWithPreferences:preferences" not in relay:
        raise RuntimeError(".89 candidate differs; do not assert against stale source")
    if 'DFCall0(self.scene,@"clientSettings")' not in host:
        raise RuntimeError("expected .89 client settings readback missing")
    if "MSHookMessageEx" in relay:
        raise RuntimeError("Expected first-party relay has not installed original global hooks")
    if "DFSceneLifecycle.m" not in (src / "sideplay/duoface-native-scene-host/build.sh").read_text():
        raise RuntimeError(".83 playback lifecycle safety boundary missing")
    orig_reflow = archive["functions"]["app_state_UIKit_reflow_dispatch"]["original_arm64"]
    refs = [x for x in orig_reflow if "Objc selector ref:" in x["asm"]]
    for name in ("windows", "allWindowsIncludingInternalWindows:onlyVisibleWindows:",
                 "_rotateWindowToOrientation:updateStatusBar:duration:skipCallbacks:"):
        if not any(name in x["asm"] for x in refs):
            raise RuntimeError("original two-pass UIKit reflow reference missing: " + name)
    apply = archive["functions"]["app_state_async_state_apply_block"]["original_arm64"]
    bl = [(x["pc"], x["asm"]) for x in apply if x["asm"].startswith("bl")]
    if not any(x[1] == "bl\\t0x2a9e38" for x in bl):
        raise RuntimeError("original app state callback does not connect to reflow")
    if not any(x["asm"].startswith("bl\\t0x2ec9a0") for x in original):
        raise RuntimeError("original installer has no direct hook stub calls")
    return {
        "status": "NATIVE12_ORIGINAL_ACTUAL_DEB_VERIFIED_NOT_YOUTUBE_DEVICE_FIX",
        "original_deb_sha256": EXPECTED_DEB,
        "original_dashboard_dylib_sha256": EXPECTED_IMAGE,
        "original_hook_installer_arm64": "0x2ac688..0x2acc04",
        "original_hook_install_sites": len(hooks),
        "verified_class_selector_sites": [
            {"class": cls, "selector": sel, "pc": exact[(cls, sel)]}
            for cls, sels in SELECTORS.items() for sel in sels
        ],
        "additional_install_sites_not_classified": [
            x for x in hooks if (x["class"], x["selector"]) not in
            {(c, s) for c, sels in SELECTORS.items() for s in sels}
        ],
        "app_state_delivered_then_reflows": {
            "callback": "0x2abd98",
            "direct_reflow_call": next(x[0] for x in bl if x[1] == "bl\\t0x2a9e38"),
            "reflow": "0x2a9e38..0x2aa684",
        },
        "duoface_089_gap_verified": [
            "v2 isSplit and 120-ms one-shot portrait geometry request do not reproduce original process-local UIKit/UIScreen/UIDevice orientation virtualization",
            "original has distinct UIViewController.supportedInterfaceOrientations and UIWindowScene.interfaceOrientation hook installation sites",
            "original has UIDevice.orientation and UIScreen.bounds/nativeBounds/_referenceBounds hook sites; .89 has none in YouTube receiver",
            "original also intercepts applicationState, window geometry, statusBarOrientation and scene lifecycle; these have not been mapped to individual callback return values",
            "original 36 installation callsites do not prove all hooks execute inside this YouTube version; do not implement blindly",
        ],
        "device_089_result": "FAIL per user; wrong YouTube video orientation in split",
        "not_proven": [
            "which original callback transforms the YouTube player's orientation",
            "that copying all original hooks is safe or permitted",
            "that original runtime values for every hook have been reverse engineered",
            "that a future .90 is working on device",
        ],
        "next": "resolve actual original callback targets and bridge-enabled/split predicates per relevant selector, compare against observed video vs controller orientation; design independent gated equivalent and run on-device logs",
    }


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--original-json", required=True, type=Path)
    p.add_argument("--original-deb", required=True, type=Path)
    p.add_argument("--original-dashboard", required=True, type=Path)
    p.add_argument("--src", default=".", type=Path)
    p.add_argument("--output", required=True, type=Path)
    args = p.parse_args()
    data = inspect(json.loads(args.original_json.read_text()), args.src,
                   args.original_deb, args.original_dashboard)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    rendered = json.dumps(data, ensure_ascii=False, indent=2) + "\n"
    args.output.write_text(rendered, encoding="utf8")
    if args.output.read_text(encoding="utf8") != rendered:
        raise RuntimeError("audit readback failed")
    print("NATIVE12_ORIGINAL_VERIFIED_REAL_DEB_HOOK_PARITY_GAP_PASS",
          data["original_hook_install_sites"], len(data["verified_class_selector_sites"]))


if __name__ == "__main__":
    main()
