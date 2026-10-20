#!/usr/bin/env python3
"""Pure offline analyzer. No device calls, no repository modifications."""
import argparse
import json
import re
from pathlib import Path

def analyze(trace, spring, request_id, car_icon_seen=False, native_scene=""):
    event_lines=[line for line in trace.splitlines() if "run="+request_id in line]
    samples=[s for s in event_lines if "sample=" in s and "originalClass=" in s]
    typed3=[s for s in samples if "selector=typed3" in s]
    sb_lines=[line for line in spring.splitlines() if "request="+request_id in line]
    spring_found=any("target-found process=SpringBoard" in line for line in sb_lines)
    spring_absent=any("target-absent" in line for line in sb_lines)
    scene_connected="native-carplay-scene-connected" in native_scene
    h2="UNKNOWN_no_target_getter_sample"
    if typed3:
        h2=("POSSIBLE_values_class_mismatch" if any(
           "valuesExpected=NSNumber" not in s or "expected=NSNumber" not in s for s in typed3
        ) else "NOT_OBSERVED_in_sample")
    status=("ICON_AND_NATIVE_SCENE_OBSERVED" if car_icon_seen and scene_connected
        else "NO_PHYSICAL_ICON_UNRESOLVED" if event_lines or sb_lines
        else "INSUFFICIENT_FRESH_EVIDENCE")
    return {
        "request_id":request_id,"status":status,"sample_count":len(samples),
        "hooks_ready":any("hook-ready" in s for s in event_lines),
        "firstparty_typed3_call_seen":bool(typed3),
        "springboard_proxy":"present" if spring_found else "absent" if spring_absent else "unknown",
        "real_car_icon":car_icon_seen,"system_issued_scene":scene_connected,
        "hypotheses":{
          "H1_other_process_or_filtered_roster":"INDETERMINATE_not_measured",
          "H2_class_guards":h2,
          "H3_library_built_before_hook":"INDETERMINATE_no_library_creation_timestamp"
        },
        "limitations":[
          "Hook armed is not entitlement override success",
          "Proxy visible is not physical Dashboard membership",
          "Zero samples does not prove any particular process or timing",
          "Direct SpringBoard query cannot identify cached-values receiver"
        ]
    }

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--trace",type=Path,required=True)
    ap.add_argument("--springboard",type=Path,required=True)
    ap.add_argument("--request-id",required=True)
    ap.add_argument("--car-icon-seen",action="store_true")
    ap.add_argument("--scene-log",type=Path)
    ap.add_argument("--output",type=Path)
    a=ap.parse_args()
    result=analyze(a.trace.read_text(errors="replace"),
                   a.springboard.read_text(errors="replace"),a.request_id,
                   a.car_icon_seen,a.scene_log.read_text(errors="replace") if a.scene_log else "")
    data=json.dumps(result,sort_keys=True,ensure_ascii=False,indent=2)+"\n"
    if a.output:
        a.output.parent.mkdir(parents=True,exist_ok=True)
        a.output.write_text(data)
    else:print(data)
if __name__=="__main__":main()
