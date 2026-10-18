#!/usr/bin/env python3
"""Reproducible *configuration-only* SidePlay normal-CarPlay candidate.

The stock DEB/binary remains immutable. Changing the preference panel's
'default' does not override an already persisted com.sideplay carDock=false;
export a separate, inspectable CFPreferences plist for device QA instead.

No package build, no install, no use of original proprietary Mach-O code.
"""
from __future__ import annotations

import argparse
import copy
import plistlib
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
STOCK = REPO / "sideplay/extracted-1.0.4-1/rootfs/var/jb/Library/PreferenceBundles/SidePlayPrefs.bundle/Root.plist"
CANDIDATE = REPO / "sideplay/normal-carplay/SidePlayPrefs.bundle/Root.plist"
DOMAIN = "com.sideplay"


def load(path: Path) -> dict:
    with path.open("rb") as f:
        data = plistlib.load(f)
    if not isinstance(data, dict):
        raise ValueError(f"{path}: plist root not a dictionary")
    return data


def row_by_key(root: dict, key: str) -> dict:
    matches = [x for x in root.get("items", []) if isinstance(x, dict) and x.get("key") == key]
    if len(matches) != 1:
        raise ValueError(f"Expected exactly one setting {key}, found {len(matches)}")
    return matches[0]


def verify_candidate() -> dict:
    stock = load(STOCK)
    candidate = load(CANDIDATE)
    dock = row_by_key(stock, "carDock")
    if dock.get("default") is not False:
        raise ValueError("Upstream carDock default has changed; re-audit")
    wanted = copy.deepcopy(stock)
    row_by_key(wanted, "carDock")["default"] = True
    if candidate != wanted:
        raise ValueError("Candidate differs beyond carDock default; REFUSE")
    for key, value in (("autoFitCar", True), ("autoHideBar", True)):
        if row_by_key(stock, key).get("default") is not value:
            raise ValueError(f"Upstream {key} changed; re-audit")
    if row_by_key(stock, "carZoom").get("default") != 100:
        raise ValueError("Upstream carZoom changed; re-audit")
    return {"domain": DOMAIN, "key": "carDock", "original_default": False, "candidate_default": True,
            "other_preference_rows_unchanged": True}


def build_prefs(source: Path | None, output: Path) -> dict:
    if source:
        if source.resolve() == output.resolve():
            raise ValueError("Original preferences must not be overwritten")
        values = load(source)
    else:
        values = {}
    before = values.get("carDock", None)
    values["carDock"] = True
    # Do not touch autoOpen, restoreLast, licensing, HUD, scene hosts, etc.
    output.parent.mkdir(parents=True, exist_ok=True)
    if output.exists():
        raise ValueError(f"Output already exists: {output}")
    with output.open("wb") as f:
        plistlib.dump(values, f, fmt=plistlib.FMT_XML, sort_keys=True)
    return {"domain": DOMAIN, "old_carDock": before, "new_carDock": True,
            "untouched_keys": sorted(k for k in values if k != "carDock"),
            "output": str(output)}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--verify", action="store_true", help="Only verify isolated panel change")
    parser.add_argument("--prefs-input", type=Path, default=None,
                        help="Optional existing com.sideplay plist to preserve all unrelated keys")
    parser.add_argument("--prefs-output", type=Path, default=None,
                        help="Write a separate candidate plist, never the original")
    args = parser.parse_args()
    result = verify_candidate()
    if args.prefs_output:
        result["prefs"] = build_prefs(args.prefs_input, args.prefs_output)
    elif args.prefs_input:
        parser.error("--prefs-input requires --prefs-output")
    print(result)


if __name__ == "__main__":
    main()
