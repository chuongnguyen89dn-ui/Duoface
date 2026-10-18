#!/usr/bin/env python3
"""Narrow ORIGINAL SidePlay picker/launch event inspection for DuoFace app cards.

No executing, patching, license API, or re-scanning other DEBs. The hashed,
already-extracted original SidePlay.dylib is read only for the targeted Objective-C
SPDash and SPPane picker/launch/selection methods. Inherited QA parser used.
"""
import hashlib
import json
import os
import re
import sys
from pathlib import Path

ROOT=Path(__file__).resolve().parents[3]
SOURCE=ROOT/"sideplay/extracted-1.0.4-1/rootfs/var/jb/Library/MobileSubstrate/DynamicLibraries/SidePlay.dylib"
INVENTORY=ROOT/"sideplay/audit/deb-1.0.4-1/inventory.json"
OUT=ROOT/"sideplay/native12-display/audit/SP_PICKER_DISPATCH.json"
FILTER=re.compile(r"pick|choose|app|scene|launch|recent|bundle|open|select|"
                  r"activate|paneRequest|card|layout",re.I)
TARGET={"SPDash","SPPane"}
raw=SOURCE.read_bytes()
inventory=json.loads(INVENTORY.read_text())
sha=next(x["sha256"] for x in inventory
         if x.get("scope")=="rootfs" and x.get("path","").endswith("/SidePlay.dylib"))
assert hashlib.sha256(raw).hexdigest()==sha,"Original extracted dylib hash mismatch"
sys.path.insert(0,os.environ["SIDEPLAY_PARSER_DIR"])
from audit_native12_license_class_xrefs import MachO,select_arm64
from audit_native12_carplay_add_app_chain import methods,disassemble
m=MachO(select_arm64(raw))
report={"original_sha256":sha,"target_classes":list(TARGET),
        "kind":"STATIC method and callsite traces; NOT executable launch validation",
        "methods":{}}
for name in sorted(TARGET):
    pool=methods(m,name)
    selected={}
    for selector,rec in pool.items():
        if not FILTER.search(selector):continue
        vm=rec["vm"]
        # Limit evidence per method to first 0x160 bytes. No full binary scan.
        sample=disassemble(m,vm,vm+0x160)
        selected[selector]={"imp":hex(vm),"objc_type":rec["type"],
                             "asm_excerpt":sample}
    report["methods"][name]=selected
OUT.parent.mkdir(parents=True,exist_ok=True)
OUT.write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
print(json.dumps({"original_sha256":sha,
      "methods":{k:list(v) for k,v in report["methods"].items()},
      "report_bytes":OUT.stat().st_size},ensure_ascii=False))
