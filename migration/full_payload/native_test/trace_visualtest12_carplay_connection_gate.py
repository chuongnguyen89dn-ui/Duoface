#!/usr/bin/env python3
"""Explain 2026-10-17 real-device "CarPlay not connected" despite iOS connection.

Read-only, compares PINNED VisualTest12 original and published Launchfix1 ARM64
for exact CarPlay detector/bridge/state code; no patches, DEB builds, or Sileo.
The report does not infer live device values from static identical bytes.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

from audit_native12_license_class_xrefs import BINARIES, MachO, select_arm64
from audit_visualtest12_macho_vm_abi import method_table

ROOT = Path(__file__).resolve().parents[3]
OLD = ROOT / "dist/visual-1.0.3-12/com.duoface.app_1.0.3-12_visualtest_iphoneos-arm64.deb"
NEW = ROOT / "dist/visualtest12-launchfix1/com.duonavi.app_1.0.3-12~visualtest12launch1_iphoneos-arm64.deb"
OLD_SHA = "8b7dedf77b9ec05465b83fdb6e2d7127800eac232a34ecf12f2c08b3983a481a"
NEW_SHA = "e30148affc767ce039040f0e0cccd9a0ecbd40e523ee66409ca96e6ef2085f02"

WATCH = {
    "DuoFaceUI": {
        "CBLicenseSyncManager": [
            "-isCarPlayScreenConnected", "+isCarPlayScreenConnected",
            "+isCarPlayScreen:", "+isCarPlayScreenConnectedExcludingScreen:",
            "-isLicenseCurrentlyValid",
        ],
        "CBGeneralSettingsViewController": [
            "-handleAppDidBecomeActive", "-viewWillAppear:", "-autoLaunchOnConnect",
        ],
    },
    "DuoFaceDashboard": {
        "CBLicenseSyncManager": [
            "-isCarPlayScreenConnected", "+isCarPlayScreenConnected",
            "+isCarPlayScreen:", "+isCarPlayScreenConnectedExcludingScreen:",
            "-isLicenseCurrentlyValid",
        ],
        "CBBridgeManager": [
            "-handleCarPlayConnectionChanged:", "-handleScreenDidConnect:",
            "-handleScreenDidDisconnect:", "-handleGenericScreenOrCarPlayNotification:",
            "-requestStateChange:", "-loadNewAppFromCurrentRequest:",
            "-shouldBridge:", "-syncDashboardPolicySignalToDisk",
        ],
        "CBBridgeManagerDashboard": [
            "-handleScreenDidConnect:", "-handleScreenDidDisconnect:",
            "+isDashboardPolicySignalActive", "+shouldInterceptLaunchForApp:",
            "-requestActivation:", "-startBridging:",
        ],
    },
}

def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

def text_region(m: MachO) -> dict:
    sec = [x for x in m.sections if x["segment"] == "__TEXT" and x["name"] == "__text"]
    assert len(sec) == 1
    return sec[0]

def known_imps(m: MachO) -> list[int]:
    result = set()
    for owner in m.classes():
        for info in method_table(m, owner).values():
            if info["imp_vm"]:
                result.add(info["imp_vm"])
    return sorted(result)

def bounded_span(m: MachO, methods: list[int], addr: int) -> bytes:
    section = text_region(m)
    assert section["vm"] <= addr < section["vm"] + section["size"]
    next_addrs = [x for x in methods if x > addr]
    stop = min(next_addrs, default=section["vm"] + section["size"])
    assert 4 <= stop - addr <= 300000, (hex(addr), stop - addr)
    off = m.map(addr)
    assert off + stop - addr <= len(m.data)
    return m.data[off:off + stop - addr]

def analyse_method(a: MachO, b: MachO, owner: str, sel: str,
                   imps_a: list[int], imps_b: list[int]) -> dict:
    av, bv = method_table(a, owner).get(sel), method_table(b, owner).get(sel)
    if av is None or bv is None:
        return {"present_both": False, "present_original": av is not None,
                "present_launchfix1": bv is not None}
    left = bounded_span(a, imps_a, av["imp_vm"])
    right = bounded_span(b, imps_b, bv["imp_vm"])
    return {
        "present_both": True,
        "type_unchanged": av["type"] == bv["type"],
        "imp_vm_unchanged": av["imp_vm"] == bv["imp_vm"],
        "vm_original": hex(av["imp_vm"]), "vm_launchfix1": hex(bv["imp_vm"]),
        "original_approx_upper_bound_bytes": len(left),
        "launchfix1_approx_upper_bound_bytes": len(right),
        "whole_upper_bound_equal": left == right,
        "first_24_equal": left[:24] == right[:24],
        "original_first_24_bytes": left[:24].hex(),
        "launchfix1_first_24_bytes": right[:24].hex(),
        "changed_count_at_same_length": (sum(x != y for x,y in zip(left,right))
                                         if len(left)==len(right) else None),
        "original_sha256": sha(left),
        "launchfix1_sha256": sha(right),
        "note": "IMP to next ObjC IMP is an upper bound; can contain non-ObjC helpers",
    }

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--output", type=Path, required=True)
    opts = ap.parse_args()
    assert sha(OLD.read_bytes()) == OLD_SHA
    assert sha(NEW.read_bytes()) == NEW_SHA
    def field(p: Path, name: str) -> str:
        return subprocess.check_output(["dpkg-deb","-f",str(p),name], text=True).strip()
    assert field(OLD,"Package") == field(NEW,"Package") == "com.duonavi.app"
    assert field(OLD,"Version") == "1.0.3-12~visualtest"
    assert field(NEW,"Version") == "1.0.3-12~visualtest12launch1"
    with tempfile.TemporaryDirectory(prefix="visualtest12-carplay-gate-") as temp:
        root=Path(temp)
        for n, deb in (("old",OLD),("new",NEW)):
            subprocess.run(["dpkg-deb","-x",str(deb),str(root/n)],check=True)
        hosts={}
        for host, rel in BINARIES.items():
            a=MachO(select_arm64((root/"old"/rel).read_bytes()))
            b=MachO(select_arm64((root/"new"/rel).read_bytes()))
            a_imps, b_imps=known_imps(a), known_imps(b)
            methods={}
            for owner, selectors in WATCH[host].items():
                for sel in selectors:
                    key=owner+"::"+sel
                    methods[key]=analyse_method(a,b,owner,sel,a_imps,b_imps)
            hosts[host]=methods
    all_methods=[v for h in hosts.values() for v in h.values()]
    preserved_detectors=[v for h in hosts.values() for k,v in h.items()
                         if k.startswith("CBLicenseSyncManager::") and
                         "isCarPlayScreen" in k]
    assert len(preserved_detectors)==8
    summary={
        "watched":len(all_methods),
        "present_both":sum(v["present_both"] for v in all_methods),
        "identical_bounded_bytes":sum(v.get("whole_upper_bound_equal",False) for v in all_methods),
        "different_bounded_bytes":sum(v.get("whole_upper_bound_equal") is False for v in all_methods),
        "all_8_carplay_detection_implementations_byte_identical":
            all(v["present_both"] and v["whole_upper_bound_equal"] for v in preserved_detectors),
        "watch_carplay_connection_and_bridge_methods_identical":
            all(v.get("whole_upper_bound_equal") is True for h in hosts.values()
                for k,v in h.items() if not k.endswith("-isLicenseCurrentlyValid")
                and v["present_both"]),
        "license_getters_changed_as_intended":
            sum(v.get("whole_upper_bound_equal") is False for h in hosts.values()
                for k,v in h.items() if k.endswith("-isLicenseCurrentlyValid")),
    }
    result={
        "status":"VISUALTEST12_LAUNCHFIX1_CARPLAY_CONNECTION_GATE_STATIC_TRIAGE",
        "real_world_user_observation":"physical CarPlay connected; DuoFace reports disconnected; app and unofficial apps cannot launch",
        "comparison_only":True,"source_old_sha256":OLD_SHA,
        "source_launchfix_sha256":NEW_SHA,
        "summary":summary,"binaries":hosts,
        "connection_runtime_value_verified":False,
        "carbridge_external_tweak_installed_or_required_verified":False,
        "root_cause_proven":False,
        "new_deb_built":False,"sileo_modified":False,"hub_modified":False,
        "next":"Capture SpringBoard and DuoFaceUI detector results + actual UIScreen/CarPlay scene and bridge activation at the SAME time; do not force boolean true on disconnected hardware",
    }
    opts.output.parent.mkdir(parents=True,exist_ok=True)
    opts.output.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n")
    print(json.dumps({"status":result["status"],"summary":summary},indent=2))
if __name__=="__main__":
    main()
