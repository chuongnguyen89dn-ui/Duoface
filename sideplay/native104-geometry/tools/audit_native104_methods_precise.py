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
import struct
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
    raw=extract_binary()
    m=MachO(select_arm64(raw))
    classes=m.classes()
    # Next ObjC IMP is a bound for inspection, not a verified function end.
    byclass={}
    starts=set()
    for name in classes:
        try:
            mm=methods(m,name)
            byclass[name]=mm
            starts.update(v["vm"] for v in mm.values() if v.get("vm"))
        except (ValueError,KeyError,IndexError,AssertionError):
            continue
    starts=sorted(starts)
    # Addresses taken only from verified handleDividerPan and layoutSplitViews
    # disassembly of this SHA-pinned binary; read constants, do not guess clamp.
    ratio_addrs={
        "pan_lower_bound":0x33c828,
        "pan_upper_bound":0x33c830,
        "pan_snap_offset_a":0x33f5a8,
        "pan_snap_offset_b":0x33f5b0,
        "pan_snap_threshold":0x33e5b8,
    }
    literals={}
    for name,addr in ratio_addrs.items():
        try:
            val=struct.unpack_from("<d",m.data,m.map(addr))[0]
            literals[name]={"address":hex(addr),"value":val}
        except (ValueError,KeyError,IndexError,struct.error) as err:
            literals[name]={"address":hex(addr),"error":str(err)}
    out={"status":"STATIC ORIGINAL DUONAVI 1.0.4 DIRECT OBJC CLASS METHODS",
         "original_deb_sha256":EXACT_SHA,"dashboard_sha256":digest(raw),
         "arm64_sha256":digest(select_arm64(raw)),
         "qa_parser_source_ref":"feature/visual12-duodash-recovery",
         "methods":{},"missing":[],"ratio_literal_values":literals,"not_licensing_source":True,"device_tested":False}
    for cls,selectors in CLASSES.items():
        if cls not in classes:
            out["missing"].append("CLASS "+cls)
            continue
        byname=byclass.get(cls,methods(m,cls))
        classout={}
        for wanted in selectors:
            method=byname.get("-"+wanted) or byname.get("+"+wanted)
            if not method:
                out["missing"].append("METHOD "+cls+" "+wanted)
                continue
            start=method["vm"]
            ix=bisect.bisect_right(starts,start)
            end=starts[ix] if ix<len(starts) else start+1024
            # disassemble at most 0x2400 bytes for large complex layouts,
            # truncation explicitly marked (not a complete reconstruction).
            stop=min(end,start+0x2400)
            asm=disassemble(m,start,stop)
            classout[wanted]={"imp":hex(start),"end":hex(end),"traced_end":hex(stop),
                    "truncated":end>stop or len(asm)>=1400,
                    "end_is_next_objc_imp_not_function_boundary":True,
                    "objc_type":method["type"],"instructions":asm}
        out["methods"][cls]=classout
    DEST.parent.mkdir(parents=True,exist_ok=True)
    DEST.write_text(json.dumps(out,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({"deb_sha":EXACT_SHA,"binary_sha":out["dashboard_sha256"],
          "classes":{k:{n:v["imp"] for n,v in sub.items()} for k,sub in out["methods"].items()},
          "missing":out["missing"],"ratio_literal_values":literals,"size_bytes":DEST.stat().st_size},ensure_ascii=False,indent=2))
if __name__=="__main__":main()
