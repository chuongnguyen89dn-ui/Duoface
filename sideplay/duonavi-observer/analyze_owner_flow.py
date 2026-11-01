#!/usr/bin/env python3
"""Evidence-only parsing for observer 0.0.4 original-bridge owner trace.

No inferred caller, class, picker screen, or frame/touch success. Input is
concatenated rotated .jsonl exports; line order is not chronological.
"""
import argparse
import json
from collections import Counter
from pathlib import Path

VERSION = "0.0.4~ownerflow1"
RESULT_MARKERS = {"RESULT_APP_CHOOSER", "RESULT_CARPLAY_HOME"}


def analyze(text):
    records, markers = [], []
    for n, line in enumerate(text.splitlines(), 1):
        if not line.startswith("{"):
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        if not isinstance(row, dict):
            continue
        if row.get("event") == "manual_mark" and row.get("stage") in RESULT_MARKERS:
            markers.append({"utc": row.get("utc"), "stage": row["stage"],
                            "export_line": n})
        if row.get("observer_version") == VERSION:
            row["export_line"] = n
            records.append(row)
    records.sort(key=lambda r: (float(r.get("utc") or 0), r["export_line"]))
    calls = [r for r in records if r.get("event") == "home_flow_call"]
    events = []
    for r in calls:
        name = r.get("selector")
        phase = r.get("phase")
        if name == "appForBundleIdentifier:frame:" and phase in ("enter", "factory-return"):
            events.append({"event": "factory", "phase": phase, "utc": r.get("utc"),
                           "line": r["export_line"], "process": r.get("process"),
                           "run": r.get("run"), "call": r.get("call"),
                           "bundle": (r.get("argument") or {}).get("string"),
                           "frame": r.get("frame"),
                           "returned_class_identity": r.get("factoryResult")})
        elif name == "showAppPickerForSlot:" and phase == "enter":
            events.append({"event": "picker_method_enter", "utc": r.get("utc"),
                           "line": r["export_line"], "process": r.get("process"),
                           "slot": r.get("slotIndex"), "receiver": r.get("receiver")})
        elif name in ("notifyStateUpdated", "deactivateCurrentApp",
                      "requestStateChangeWithDictionary:") and phase in ("enter", "return"):
            owner = (r.get("snapshot") or {}).get("bridge_owner") or {}
            if owner.get("status") == "runtime-manager-getters":
                events.append({"event": "live_manager_readback", "utc": r.get("utc"),
                               "line": r["export_line"], "process": r.get("process"),
                               "selector": name, "phase": phase,
                               "manager": owner.get("manager"),
                               "bundle": owner.get("managerBundle"),
                               "current_app": owner.get("currentApp"),
                               "current_app_bundle": owner.get("currentAppBundle"),
                               "bridge_window": owner.get("bridgeWindow"),
                               "root_window": owner.get("rootWindow"),
                               "root_window_getter": owner.get("rootWindowGetter")})
    starts = {(r.get("process"), r.get("pid"), r.get("run"), r.get("call")): r
              for r in calls if r.get("selector") == "homeButtonUp:"
              and r.get("phase") == "enter"}
    homes = []
    for r in calls:
        if r.get("selector") != "homeButtonUp:" or r.get("phase") != "return":
            continue
        key = (r.get("process"), r.get("pid"), r.get("run"), r.get("call"))
        before = starts.get(key)
        if before is None:
            continue
        homes.append({"utc": before.get("utc"), "enter_line": before["export_line"],
                      "return_line": r["export_line"], "process": r.get("process"),
                      "native_bundle_on_enter": (before.get("snapshot") or {}).get("activeBundle")})
    types = Counter(str(e["returned_class_identity"]).split(":")[0]
                    for e in events if e["event"] == "factory"
                    and e["phase"] == "factory-return" and e["returned_class_identity"]
                    and e["returned_class_identity"] != "nil")
    status = Counter(((r.get("snapshot") or {}).get("bridge_owner") or {}).get("status")
                     for r in calls if ((r.get("snapshot") or {}).get("bridge_owner") or {}).get("status"))
    return {"version": VERSION, "records": len(records), "method_events": events,
            "observed_factory_return_classes": dict(types),
            "manager_snapshot_statuses": dict(status),
            "home_enter_return_pairs": sorted(homes, key=lambda x: x["utc"] or 0),
            "manual_outcome_markers": sorted(markers, key=lambda x: x["utc"] or 0),
            "missing": {
                "original_factory_return_class": not bool(types),
                "manager_current_app_readback": not any(e["event"] == "live_manager_readback"
                                                        for e in events),
                "picker_method_invocation": not any(e["event"] == "picker_method_enter"
                                                    for e in events),
                "visual_home_destination_marker": not bool(markers)},
            "limits": [
                "A returned factory object need not be displayed, ready, or accepting input.",
                "isSplit=false does not identify any concrete host class.",
                "Absence of a picker method hook or callback is not evidence it cannot run.",
                "Visual destination requires actual observed user result; no UIKit tree substitutes.",
                "Cross-process timestamps do not establish parent/caller relationships.",
                "No original vendor code, content, or license data is recorded."]}


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("log", type=Path)
    parser.add_argument("out", type=Path)
    args = parser.parse_args()
    result = analyze(args.log.read_text())
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
    print({key: result[key] for key in ("version", "records", "missing")})
