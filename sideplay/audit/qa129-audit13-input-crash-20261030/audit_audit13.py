#!/usr/bin/env python3
"""Read-only validation of an uploaded CarPlay diagnostic and SpringBoard crashes."""
import argparse
import json
import re
from collections import Counter
from pathlib import Path

p = argparse.ArgumentParser()
p.add_argument("--audit", type=Path, required=True)
p.add_argument("--ips", type=Path, nargs="+", required=True)
p.add_argument("--out", type=Path, required=True)
args = p.parse_args()
lines = args.audit.read_text(encoding="utf-8").splitlines()
header = next((s for s in lines if "exporter build " in s), "")
trace = [s for s in lines if s.startswith("utc=")]
builds = Counter(m.group(1) for s in trace if (m := re.search(r"build=(\S+)", s)))
frame = [s for s in trace if "event=scene-frame-readback" in s]
apps = Counter(m.group(1) for s in frame if (m := re.search(r"bundle=([^\s]+)", s)))
crashes = []
for path in args.ips:
    raw = path.read_text(encoding="utf-8")
    _, separator, body = raw.partition("\n")
    if not separator:
        raise ValueError("Missing IPS JSON body: " + path.name)
    data = json.loads(body)
    active = next((t for t in data.get("threads", []) if t.get("triggered")), {})
    frames = active.get("frames", []) + data.get("lastExceptionBacktrace", [])
    symbols = [f.get("symbol", "") for f in frames]
    images = {im["name"]: im.get("uuid") for im in data.get("usedImages", [])
              if im.get("name", "").startswith("DF")}
    crashes.append({
        "file": path.name,
        "capture_time": data.get("captureTime"),
        "pid": data.get("pid"),
        "exception": data.get("exception"),
        "duoface_images": images,
        "scene_observer_in_stack": any("SBAppViewController sceneHandle:" in s for s in symbols),
        "duoface_observer_in_stack": any("DFManagedSceneObserver" in s for s in symbols),
        "duoface_update_in_stack": any("DFUpdateScene" in s for s in symbols),
        "keyboard_focus_in_stack": any("SBWorkspaceKeyboardFocusController" in s for s in symbols),
    })
result = {
    "exporter_header": header,
    "line_count": len(lines),
    "timestamped_builds": dict(builds),
    "scene_readback": {"count": len(frame),
                       "same_0": sum("same=0" in s for s in frame),
                       "same_1": sum("same=1" in s for s in frame),
                       "apps": dict(apps),
                       "note": "Before geometry transaction only; not post-commit geometry proof."},
    "timestamped_pane_tap": sum("qa120-pane-tap" in s for s in trace),
    "timestamped_pane116": sum("pane116-" in s for s in trace),
    "timestamped_logo_began": sum("area=logo-control raw-began" in s for s in trace),
    "crashes": sorted(crashes, key=lambda c: c["capture_time"]),
}
args.out.mkdir(parents=True, exist_ok=True)
(args.out / "RESULT.json").write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n")
print(json.dumps(result, indent=2, ensure_ascii=False))
