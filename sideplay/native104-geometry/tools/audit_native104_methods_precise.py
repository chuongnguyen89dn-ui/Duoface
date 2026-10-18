#!/usr/bin/env python3
"""Read-only direct class/selector/IMP geometry inspection of ORIGINAL 1.0.4.

Requires existing QA branch MachO/ObjC parser mirrored into
NATIVE104_PARSER_DIR by workflow; this avoids guessing objc relative methods.
No binary rewrite or proprietary code inclusion.
"""
import bisect
import hashlib
import io
import json
import os
import sys
import tarfile
import subprocess
import tempfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[3]
SOURCE=ROOT/"dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb"
DEST=ROOT/"sideplay/native104-geometry/audit/native104-class-layout.json"
EXACT_SHA="f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd"
CLASSES={
    "CBWindow":["carPlayScreenBounds","carPlayContentInsets","carPlayUsableBounds",
                "carPlayUIScreen","carPlayScreenScale","resizeWindows"],
    "CBBridgedSplitApp":["layoutSplitViews","handleDividerPan:isVertical:state:",
                        "splitRatio","setSplitRatio:","initWithBundleIdentifier:frame:",
                        "configureDividerButtons"],
    "CBSplitContainerView":["layoutSubviews"],
    "CBBridgeManager":["receivedMetricsUpdatedNotification:","switchToSplitWithLeft:right:ratio:",
                       "switchToMultiSplitMode:apps:ratio:"],
    "CBDividerView":["updateGripLayout","pointInside:withEvent:"],
}
def digest(b):return hashlib.sha256(b).hexdigest()
def extract_binary():
    if digest(SOURCE.read_bytes()) != EXACT_SHA:
        raise ValueError("Original DuoNavi 1.0.4 package changed")
    data=subprocess.run(["dpkg-deb","--fsys-tarfile",str(SOURCE)],check=True,capture_output=True).stdout
    with tarfile.open(fileobj=io.BytesIO(data)) as tf:
        matches=[x for x in tf if x.isfile() and x.name.endswith("/DuoNaviDashboard.dylib")]
        if len(matches)!=1:raise ValueError("Original dashboard payload missing or ambiguous")
        return tf.extractfile(matches[0]).read()

def main():
    dep=os.environ.get("NATIVE104_PARSER_DIR","")
    if not dep:raise SystemExit("Missing NATIVE104_PARSER_DIR: parser must be loaded from QA source")
    sys.path.insert(0,dep)
    from audit_native12_license_class_xrefs import MachO,select_arm64
    from audit_native12_carplay_add_app_chain import methods,disassemble
    from audit_visual12_sync_callers import function_starts
    raw=extract_binary()
    m=MachO(select_arm64(raw))
    starts=function_starts(m)
    classes=m.classes()
    out={"status":"STATIC ORIGINAL DUONAVI 1.0.4 DIRECT OBJC CLASS METHODS",
         "original_deb_sha256":EXACT_SHA,"dashboard_sha256":digest(raw),
         "arm64_sha256":digest(select_arm64(raw)),
         "qa_parser_source_ref":"feature/visual12-duodash-recovery",
         "methods":{},"missing":[],"not_licensing_source":True,"device_tested":False}
    for cls,selectors in CLASSES.items():
        if cls not in classes:
            out["missing"].append("CLASS "+cls)
            continue
        byname=methods(m,cls)
        classout={}
        for wanted in selectors:
            method=byname.get("-"+wanted) or byname.get("+"+wanted)
            if not method:
                out["missing"].append("METHOD "+cls+" "+wanted)
                continue
            start=method["vm"]
            if start not in starts:
                out["missing"].append("IMP_NOT_FUNCTION_START "+cls+" "+wanted+" "+hex(start))
            ix=bisect.bisect_right(starts,start)
            end=starts[ix] if ix<len(starts) else start+1024
            # disassemble at most 0x2400 bytes for large complex layouts,
            # truncation explicitly marked (not a complete reconstruction).
            stop=min(end,start+0x2400)
            asm=disassemble(m,start,stop)
            classout[wanted]={"imp":hex(start),"end":hex(end),"traced_end":hex(stop),
                    "truncated":end>stop or len(asm)>=1400,
                    "objc_type":method["type"],"instructions":asm}
        out["methods"][cls]=classout
    DEST.parent.mkdir(parents=True,exist_ok=True)
    DEST.write_text(json.dumps(out,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({"deb_sha":EXACT_SHA,"binary_sha":out["dashboard_sha256"],
          "classes":{k:{n:v["imp"] for n,v in sub.items()} for k,sub in out["methods"].items()},
          "missing":out["missing"],"size_bytes":DEST.stat().st_size},ensure_ascii=False,indent=2))
if __name__=="__main__":main()
