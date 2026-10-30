#!/usr/bin/env python3
"""SHA-pinned, read-only binary comparison: Native12 vs OmniCar vs signed QA129.

DO NOT interpret BKSDisplayServicesSetScreenBlanked or an IOPM assertion as
proof that a phone is intentionally dimmed, that remote touch reaches YouTube,
or that iOS accepted any actual scene foreground transition.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

P = argparse.ArgumentParser()
P.add_argument("--qa129", required=True, type=Path)
P.add_argument("--native12", required=True, type=Path)
P.add_argument("--omnicar", required=True, type=Path)
P.add_argument("--source", required=True, type=Path)
P.add_argument("--out", required=True, type=Path)
args = P.parse_args()

EXPECTED = {
    "QA129": "8e9ede14c56dbf408654cd9002818a94a21272c881a73ee739012b654013017f",
    "Native12": "2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad",
    "OmniCar": "d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd",
}
FILES = {"QA129": args.qa129, "Native12": args.native12, "OmniCar": args.omnicar}
MARKERS = [
    "BKSDisplayServicesSetScreenBlanked",
    "screenBlankEnabled", "setScreenBlankEnabled:", "screenBlankToggleChanged:",
    "isIdleTimerDisabled", "setIdleTimerDisabled:", "idleTimerDisabled",
    "IOPMAssertionCreateWithName", "IOPMAssertionRelease",
    "PreventUserIdleSystemSleep", "PreventUserIdleDisplaySleep",
    "setPreventsDisplaySleepDuringVideoPlayback:",
    "SBSuspendedUnderLockManager", "_shouldBeBackgroundUnderLockForScene:withSettings:",
    "interceptUpdateForScene:withNewSettings:",
    "SBBacklightController", "setBrightness:", "setBacklightFactor:",
]
def h(path):
    hashed = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1048576), b""): hashed.update(block)
    return hashed.hexdigest()
def macho(data):
    return data[:4] in [bytes.fromhex(x) for x in (
        "cffaedfe", "feedfacf", "cafebabe", "bebafeca", "cafebabf", "bfbafeca")]
def extract(package, target):
    subprocess.run(["dpkg-deb", "-x", str(package), str(target)], check=True,
                   capture_output=True)
def strings(path):
    p = subprocess.run(["strings", "-a", "-n", "5", str(path)], check=True,
                       capture_output=True, text=True, errors="replace")
    return set(p.stdout.splitlines())

args.out.mkdir(parents=True, exist_ok=True)
records = {}
for name, deb in FILES.items():
    assert deb.is_file(), f"Missing {name} DEB"
    digest = h(deb)
    if digest != EXPECTED[name]:
        raise RuntimeError(f"{name} incorrect SHA256: {digest}")
    root = args.out / ("unpacked-" + name)
    extract(deb, root)
    found = []
    for f in sorted(root.rglob("*")):
        if not f.is_file() or not macho(f.read_bytes()[:4]): continue
        s = strings(f)
        hits = {marker: any(marker in x for x in s) for marker in MARKERS}
        if any(hits.values()):
            found.append({"path": str(f.relative_to(root)),
                          "hits": [k for k, v in hits.items() if v]})
    records[name] = {"sha256": digest, "binary_findings": found}
    # Remove extracted binary payload from permanent result: only JSON report
    # gets uploaded; original binaries must not be redistributed.
    import shutil
    shutil.rmtree(root)

def find_markers(name):
    body = (args.source / name).read_text(encoding="utf-8")
    return {k: bool(re.search(re.escape(k), body)) for k in MARKERS}
src = {name: find_markers(name) for name in (
    "DFTouchOwnerProbe.m", "DFSceneLifecycle.m",
    "DFNativeHostAppDelegate.m", "DFCarPlayDockOwner.m")}
probe = (args.source / "DFTouchOwnerProbe.m").read_text()
scene = (args.source / "DFSceneLifecycle.m").read_text()
assert "DFCarPlayPreventIdleSystemSleep121" in probe
assert 'CFSTR("PreventUserIdleSystemSleep")' in probe
assert 'DFPostLockSetBool(settings,@"idleModeEnabled"' in scene
# Assert no original-style physical display blanking/brightness hooks are
# implemented anywhere within the signed first-party runtime source set.
all_source = []
for path in sorted(args.source.glob("*")):
    if path.suffix not in (".m", ".h"): continue
    all_source.append(path.read_text(encoding="utf-8"))
combined = "\n".join(all_source)
physical = ["BKSDisplayServicesSetScreenBlanked", "setScreenBlankEnabled:",
            "setBacklightFactor:", "SBBacklightController", "setIdleTimerDisabled:"]
detected = [x for x in physical if x in combined]
assert not detected, f"First-party display control unexpectedly found: {detected}"
def package_has(pkg, marker):
    return any(marker in m["hits"] for m in records[pkg]["binary_findings"])
assert package_has("Native12", "BKSDisplayServicesSetScreenBlanked")
assert package_has("Native12", "setScreenBlankEnabled:")
assert package_has("Native12", "IOPMAssertionCreateWithName")
assert package_has("OmniCar", "BKSDisplayServicesSetScreenBlanked")
assert package_has("QA129", "IOPMAssertionCreateWithName")
assert not package_has("QA129", "BKSDisplayServicesSetScreenBlanked")
assert not package_has("QA129", "setScreenBlankEnabled:")
result = {
    "kind": "original-vs-signed-qa129-phone-screen-and-lock-forensics",
    "signed_package_sha_verified": True,
    "records": records,
    "source_markers": src,
    "qa129_has_system_idle_assertion": True,
    "qa129_has_native12_screen_blank_toggle_or_blank_api": False,
    "qa129_idleModeEnabled_is_hosted_scene_settings_not_iphone_brightness": True,
    "omnicar_has_BKS_symbol_but_actual_called_path_and_phone_dim_unproved": True,
    "native12_has_BKS_and_screen_blank_toggle_symbols_but_active_call_unproved": True,
    "qa129_tap_when_locked_root_cause": "not measured by static scan",
    "security_and_safety": "No changing phone-lock policy, brightness, power, system entitlements or input synthesis",
}
out = args.out / "RESULT.json"
out.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print("SIGNED_QA129_HAS_IOPM_NO_SCREEN_BLANK_CONTROL_OR_DIM_HANDLER_NATIVE12_AND_OMNICAR_DIFFER_VERIFIED")
