#!/usr/bin/env python3
"""Static read-only Native12 CPU/thermal setting, display cadence and screen-blank audit.

Only binary metadata, ASCII selectors and file content; does not execute tweaks,
measure CPU/temperature/FPS on an iPhone, or modify a native12 DEB.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import re
import subprocess
import tempfile
from pathlib import Path

from audit_native12_license_class_xrefs import MachO, select_arm64, BINARIES, NATIVE12_SHA
from audit_native12_carplay_add_app_chain import methods, disassemble

SIGNATURES = [
    "perf_tweak_enabled",
    "thermalState",
    "thermalStateDidChangeNotification",
    "NSProcessInfoThermalStateDidChangeNotification",
    "CADisplayLink",
    "preferredFrameRateRange",
    "preferredFramesPerSecond",
    "setPreferredFramesPerSecond:",
    "setPreferredFrameRateRange:",
    "maximumFramesPerSecond",
    "screenBlankEnabled",
    "screenBlankToggleChanged:",
    "setScreenBlankEnabled:",
    "dockSystemMonitorEnabled",
    "CACurrentMediaTime",
    "setAnimationDuration:",
    "setFrameInterval:",
    "NSTimer",
]
METHOD_PATTERN = re.compile(
    r"screenBlank|cpu|thermal|perf|framerate|frameRate|fps|displayLink|"
    r"animation|monitor|timer|layoutSubviews|render|refresh|blink|background", re.I)
EXACT_SIGNED_SHA = {
    "DuoFaceUI":"cb40346d8ca504cb399abe31367847b4f980a01ba93810986ce1acf1fbe9eef9",
    "DuoFaceDashboard":"9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea",
}
OWNER_CLASSES={
    "DuoFaceUI":["CBGeneralSettingsViewController"],
    "DuoFaceDashboard":["CBDashboardSettings"],
}
OWNER_METHODS={
    "DuoFaceUI":["screenBlankToggleChanged:","savePreferences","loadPreferences"],
    "DuoFaceDashboard":["screenBlankEnabled","setScreenBlankEnabled:"],
}
def hash_bytes(raw): return hashlib.sha256(raw).hexdigest()

def inspect_one(binary, data):
    assert hash_bytes(data)==EXACT_SIGNED_SHA[binary], f"{binary}: immutable signed SHA changed"
    m=MachO(select_arm64(data))
    classes=m.classes()
    interesting=[]
    for name, cls in sorted(classes.items()):
        matches=[method for method in cls["methods"] if METHOD_PATTERN.search(method)]
        if matches: interesting.append({"class":name,"methods":matches[:75]})
    texts={}
    for word in SIGNATURES:
        raw=word.encode("utf-8")
        positions=[z.start() for z in re.finditer(re.escape(raw),data)]
        texts[word]={"raw_literal_occurrences":len(positions),"sample_file_offsets":[hex(p) for p in positions[:8]]}
    owners={}
    for c in OWNER_CLASSES[binary]:
        if c not in classes:
            owners[c]={"present":False}
            continue
        mets=methods(m,c)
        sorted_m=sorted([int(x["vm"]) for x in mets.values() if x["vm"]])
        data_methods={}
        for target in OWNER_METHODS[binary]:
            item=mets.get("-"+target) or mets.get("+"+target)
            if item is None:
                data_methods[target]={"present":False}
                continue
            start=int(item["vm"])
            end=next((p for p in sorted_m if p>start),start+960)
            instructions=disassemble(m,start,min(end,start+960))
            data_methods[target]={"present":True,"imp_vm":hex(start),"abi":item["type"],
                "sample_code":instructions[:45]}
        owners[c]={"present":True,"methods":data_methods}
    return {"sha256":hash_bytes(data),"objc_classes_total":len(classes),
        "matched_method_groups":interesting,"signature_evidence":texts,"owner_routes":owners}

def main():
    a=argparse.ArgumentParser()
    a.add_argument("--deb",required=True,type=Path)
    a.add_argument("--out",required=True,type=Path)
    args=a.parse_args()
    packaged=args.deb.read_bytes()
    assert hash_bytes(packaged)==NATIVE12_SHA
    assert subprocess.check_output(
        ["dpkg-deb","-f",str(args.deb),"Version"],text=True).strip()=="0.1.0~native12"
    report={"status":"NATIVE12_CPU_THERMAL_READONLY_AUDIT_PASS",
       "baseline_package":"com.duoface.independent",
       "baseline_sha256":NATIVE12_SHA,
       "source_branch":"feature/duoface-exact-payload-migration",
       "tweak_or_deb_modified":False,
       "runtime_fps_tested":False,
       "runtime_cpu_tested":False,
       "runtime_thermal_tested":False,
       "scope":"Static symbols/strings/method ABIs on exact signed native12 payload; not proof all dynamic functions absent",
       "binaries":{}}
    with tempfile.TemporaryDirectory(prefix="df-native12-cpu-audit-") as temp:
        subprocess.run(["dpkg-deb","-x",str(args.deb),temp],check=True)
        for name, rel in BINARIES.items():
            raw=(Path(temp)/rel).read_bytes()
            report["binaries"][name]=inspect_one(name,raw)
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    for name,v in report["binaries"].items():
        present=[k for k,x in v["signature_evidence"].items() if x["raw_literal_occurrences"]]
        print("BINARY",name,"SHA256",v["sha256"],"SELECTOR_GROUPS",len(v["matched_method_groups"]))
        print("SIGNED_RAW_SIGNATURES_PRESENT",name,present)
        print("CONTROL_OWNERS",name,{k:v2["methods"] if v2.get("present") else None
              for k,v2 in v["owner_routes"].items()})
    print("NATIVE12_CPU_THERMAL_READONLY_AUDIT_PASS")
if __name__=="__main__":
    main()
