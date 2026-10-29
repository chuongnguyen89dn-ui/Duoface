#!/usr/bin/env python3
"""Decode original Native12 dynamically installed UIWindow touch callbacks.

Derive the three C IMP addresses from SHA-verified CBWindow.createWindows,
never guessing live callbacks or linking vendor code in independent DuoFace.
"""
import argparse
import bisect
import hashlib
import json
from pathlib import Path
import re
import subprocess

EXPECTED_DASH = "9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea"
EXPECTED_DEB = "2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad"
BASE = Path(__file__).resolve().parent
INSN = re.compile(r"^\s*([0-9a-fA-F]+):\s+(\w[\w.]*)\s*(.*)$")


def main() -> None:
    parser=argparse.ArgumentParser()
    parser.add_argument("--binary", required=True, type=Path)
    parser.add_argument("--method-index", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    args=parser.parse_args()
    assert hashlib.sha256(args.binary.read_bytes()).hexdigest()==EXPECTED_DASH
    index=json.loads(args.method_index.read_text())
    dash=next(x for x in index["native12"] if x["filename"]=="DuoFaceDashboard.dylib")
    assert dash["sha256"]==EXPECTED_DASH
    methods=dash["objc_methods"]
    starts=sorted({int(x,16) for x in dash["lc_function_starts"]}|
                  {int(m["imp"],16) for m in methods})
    owner=json.loads((BASE/"original-owner-imp/ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json").read_text())
    assert owner["dashboard_macho_sha256"]==EXPECTED_DASH
    create=next(m for m in owner["methods"]
                if m["class"]=="CBWindow" and m["selector"]=="createWindows")
    assert int(create["imp"],16)==0xb1064
    # In actual CBWindow.createWindows each class_addMethod receives X2=ADR
    # just before hitTest / pointInside / sendEvent class_addMethod dispatch.
    offset_sites={
        "hitTest:withEvent:":0xb1370,
        "pointInside:withEvent:":0xb13b0,
        "sendEvent:":0xb13f0,
    }
    addresses={}
    for selector,pc in offset_sites.items():
        line=next((s for s in create["instructions"]
                   if s.strip().startswith(f"{pc:x}:")),None)
        if not line: raise AssertionError(f"Missing original ADR site {pc:x}")
        match=re.search(r"\badr\s+x2,\s*#(\d+)",line)
        if not match: raise AssertionError(f"Different original callback ADR: {line}")
        addresses[selector]=pc+int(match.group(1))
    if len(set(addresses.values()))!=3:raise AssertionError("IMP addresses collided")
    raw=subprocess.run(["llvm-objdump","--macho","--disassemble",
                        "--no-show-raw-insn",str(args.binary)],
                       capture_output=True,text=True,encoding="utf-8",errors="replace")
    if raw.returncode:raise RuntimeError(raw.stderr[-3000:])
    result={}
    for selector,start in addresses.items():
        nextix=bisect.bisect_right(starts,start)
        maxend=starts[nextix] if nextix<len(starts) else start+2048
        maxend=min(maxend,start+4096)
        result[selector]={"imp":hex(start),"max_end":hex(maxend),"instructions":[]}
    for line in raw.stdout.splitlines():
        m=INSN.match(line)
        if not m:continue
        pc=int(m.group(1),16)
        for selector,start in addresses.items():
            if start<=pc<int(result[selector]["max_end"],16):
                result[selector]["instructions"].append(line.strip())
    if any(len(o["instructions"])<5 for o in result.values()):
        raise AssertionError("Original dynamically installed IMP body missing")
    args.out.mkdir(parents=True,exist_ok=True)
    payload={"original_deb_sha256":EXPECTED_DEB,"dashboard_macho_sha256":EXPECTED_DASH,
             "owner_class":"CBTouchPassThroughRootSceneWindow",
             "owner_source":"CBWindow.createWindows @0xb1064 class_addMethod on runtime allocated subclass",
             "evidence_type":"ORIGINAL_ARM64_C_IMP_STATIC_NO_RUNTIME_TOUCH_PROOF",
             "callbacks":result}
    (args.out/"ORIGINAL_DYNAMIC_UIWINDOW_TOUCH_CALLBACKS.json").write_text(
        json.dumps(payload,ensure_ascii=False,indent=2)+"\n")
    lines=["# Original CBTouchPassThroughRootSceneWindow: dynamically installed C IMPs",
       "",f"- Original Native12 DEB SHA256: `{EXPECTED_DEB}`",
       f"- Dashboard SHA256: `{EXPECTED_DASH}`",
       "- Addresses derived from original CBWindow.createWindows ADR + class_addMethod.",
       "- This is original ARM64 evidence, not a DuoFace implementation or a physical touch test.",
       ""]
    for sel,o in result.items():
        lines += [f"## {sel} at {o['imp']}",f"Instructions: {len(o['instructions'])}",""]
        lines += ["    "+insn for insn in o["instructions"]]
        lines.append("")
    (args.out/"REPORT.md").write_text("\n".join(lines)+"\n")
    print("NATIVE12_ORIGINAL_DYNAMIC_WINDOW_TOUCH_CALLBACKS_VERIFIED",
          addresses,{k:len(v["instructions"]) for k,v in result.items()})


if __name__=="__main__":
    main()
