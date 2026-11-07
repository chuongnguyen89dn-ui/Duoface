#!/usr/bin/env python3
"""Fail-closed analysis of DuoFace native Maps Gate0 per-event evidence.

This never infers iPhone CarPlay Customize state from UI icons, a native
CarPlay declaration, a successful launch, or a human-entered run label.
A source must first be calibrated ON/OFF/ON for the SAME car profile.
Successful diagnostic analysis does not prove a usable native Maps pane.
"""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter, defaultdict
from pathlib import Path

MODES = frozenset(("ON", "OFF"))
MAX_AGE_MS = 2000.0
CALIBRATION_EVENT = "stock.calibration"


def read_jsonl(paths: list[str]) -> tuple[list[dict], list[dict]]:
    records: list[dict] = []
    errors: list[dict] = []
    for path in paths:
        for line_number, line in enumerate(Path(path).read_text(encoding="utf-8").splitlines(), 1):
            if not line.strip():
                continue
            try:
                record = json.loads(line)
                if not isinstance(record, dict):
                    raise ValueError("expected JSON object")
                records.append(record)
            except (ValueError, json.JSONDecodeError) as exc:
                errors.append({"source": Path(path).name, "line": line_number, "error": str(exc)})
    return records, errors


def eligible(record: dict) -> bool:
    if record.get("stockSettings") not in MODES or record.get("stockSourceStatus") != "VERIFIED":
        return False
    if record.get("stockProfileMatch") is not True:
        return False
    if not isinstance(record.get("stockSource"), str) or not record["stockSource"] or record["stockSource"].startswith("UNVALIDATED_"):
        return False
    if not isinstance(record.get("stockProfileDigest"), str) or len(record["stockProfileDigest"]) < 8:
        return False
    try:
        age = float(record.get("stockAgeMs"))
        wall = float(record.get("wall"))
        sample = float(record.get("stockSampleWall"))
    except (ValueError, TypeError):
        return False
    if not all(map(math.isfinite, (age, wall, sample))):
        return False
    if age < 0 or age > MAX_AGE_MS or sample > wall or (wall - sample) * 1000 > MAX_AGE_MS:
        return False
    return record.get("bundle") == "com.google.Maps"


def native_scene_in_record(record: dict) -> bool:
    if record.get("event") != "native.scene.snapshot" or not eligible(record):
        return False
    scenes = record.get("scenes")
    if not isinstance(scenes, list):
        return False
    for s in scenes:
        if not isinstance(s, dict):
            continue
        if (
            s.get("controller") == "DBApplicationSceneViewController"
            and s.get("sceneClass") == "FBScene"
            and s.get("windowRole") == "UIWindowSceneSessionRoleCarPlay"
            and s.get("external") is True
            and isinstance(s.get("sceneID"), str)
            and "com.google.Maps" in s["sceneID"]
        ):
            return True
    return False


def calibration_verified(rows: list[dict]) -> bool:
    """Require a documented independent UI/OS crosscheck, not just a run label."""
    ordered = sorted(
        [r for r in rows if r.get("event") == CALIBRATION_EVENT and eligible(r)
         and r.get("stockCalibrationSource") == "iOS-Customize-UI+OS-reader"
         and r.get("stockCalibrated") is True],
        key=lambda r: (r.get("wall", 0), r.get("seq", 0)),
    )
    # A single verified OS source and one exact current-car digest are required.
    sources = {(r["stockSource"], r["stockProfileDigest"]) for r in ordered}
    if len(sources) != 1:
        return False
    modes = [r["stockSettings"] for r in ordered]
    return any(modes[i:i + 3] == ["ON", "OFF", "ON"]
               for i in range(max(0, len(modes) - 2)))


def analyze(rows: list[dict], errors: list[dict] | None = None) -> dict:
    errors = errors or []
    valid = [r for r in rows if eligible(r)]
    rejected = [r for r in rows if not eligible(r)]
    reasons = Counter(
        (r.get("stockSettings", "ABSENT"), r.get("stockSourceStatus", "ABSENT"))
        for r in rejected
    )
    # Never combine distinct paired car profiles, readers or independent runs.
    grouped: dict[tuple[str, str, str], list[dict]] = defaultdict(list)
    for r in valid:
        grouped[(str(r.get("run")), r["stockSource"], r["stockProfileDigest"])].append(r)
    results: list[dict] = []
    gate = "MEASUREMENT_BLOCKED"
    for (run, source, profile), rs in sorted(grouped.items()):
        calibration = calibration_verified(rs)
        by_mode = {mode: [r for r in rs if r["stockSettings"] == mode] for mode in sorted(MODES)}
        snapshot_stats = {}
        for mode, records in by_mode.items():
            snaps = [r for r in records if r.get("event") == "native.scene.snapshot"]
            snapshot_stats[mode] = {
                "validRecords": len(records),
                "nativeSceneSnapshots": len(snaps),
                "nativeScenesObserved": sum(native_scene_in_record(r) for r in snaps),
                "absenceInterpretation": "NOT_OBSERVED_IS_NOT_PROOF_OF_NOT_CREATED",
            }
        complete = (calibration and all(snapshot_stats[m]["nativeSceneSnapshots"] > 0 for m in MODES))
        if complete:
            gate = "CALIBRATED_ON_OFF_NATIVE_SCENE_OBSERVATIONS_AVAILABLE"
        results.append({
            "run": run, "stockSource": source, "stockProfileDigest": profile,
            "calibrationON_OFF_ON": calibration, "modes": snapshot_stats,
            "analysisReady": complete,
            "offNativeSceneObserved": snapshot_stats["OFF"]["nativeScenesObserved"] > 0,
        })
    return {
        "schema": 1,
        "gate0Status": gate,
        "hardwareNativeMapsInDuoFaceAccepted": False,
        "totalRecords": len(rows), "eligibleRecords": len(valid),
        "rejectedRecords": len(rejected), "parseErrors": errors,
        "rejectedStockStates": [
            {"stockSettings": str(k[0]), "sourceStatus": str(k[1]), "count": count}
            for k, count in sorted(reasons.items(), key=lambda x: str(x[0]))
        ],
        "perSourceAndVehicleRuns": results,
        "caution": "No native scene observed under OFF != native scene impossible; no scene ACK proves display/touch",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("logs", nargs="+", help="Read-only JSONL files from parked CarPlay test")
    parser.add_argument("--output", help="Write JSON verdict (stdout otherwise)")
    args = parser.parse_args()
    records, errors = read_jsonl(args.logs)
    result = analyze(records, errors)
    text = json.dumps(result, indent=2, ensure_ascii=False, sort_keys=True) + "\n"
    if args.output:
        Path(args.output).write_text(text, encoding="utf-8")
    else:
        print(text, end="")
    return 0 if not errors else 2


if __name__ == "__main__":
    raise SystemExit(main())
