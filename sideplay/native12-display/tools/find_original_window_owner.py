#!/usr/bin/env python3
"""Targeted lookup: SidePlay class owning CarPlay window and setWindowLevel."""
import json, os, sys, hashlib
from pathlib import Path
root=Path(__file__).resolve().parents[3]
source=root/"sideplay/extracted-1.0.4-1/rootfs/var/jb/Library/MobileSubstrate/DynamicLibraries/SidePlay.dylib"
inventory=json.loads((root/"sideplay/audit/deb-1.0.4-1/inventory.json").read_text())
d=source.read_bytes()
expected=next(x["sha256"] for x in inventory if x.get("scope")=="rootfs" and x.get("path","").endswith("DynamicLibraries/SidePlay.dylib"))
assert hashlib.sha256(d).hexdigest()==expected, "Original SHA differs"
sys.path.insert(0,os.environ["SIDEPLAY_PARSER_DIR"])
from audit_native12_license_class_xrefs import MachO,select_arm64
from audit_native12_carplay_add_app_chain import methods,disassemble
m=MachO(select_arm64(d))
wanted={"makeMainScreenWindow","carWindowFrameNow","carDockMode",
        "setWindowLevel:","setWindow:","setCarWindow:","window",
        "setCarWindowFrame:","layoutRootView","carAppArea","carDockArea","carWindowFrame"}
found=[]
for name in m.classes():
    try:
        meth=methods(m,name)
    except (AssertionError,ValueError,KeyError,IndexError): continue
    matching={}
    for sel,record in meth.items():
        if sel.lstrip("-+") in wanted:
            matching[sel]={"imp":hex(record["vm"]),"type":record["type"],"asm":disassemble(m,record["vm"],record["vm"]+0x180)[:65]}
    if matching:found.append({"class":name,"matches":matching})
out={"original_sha256":expected,"count":len(found),"classes":found}
dest=root/"sideplay/native12-display/audit/SIDEPLAY_WINDOW_OWNER_CLASSES.json"
dest.parent.mkdir(parents=True,exist_ok=True)
dest.write_text(json.dumps(out,ensure_ascii=False,indent=2)+"\n")
print(json.dumps({"count":len(found),"owners":[{"class":x["class"],"selectors":list(x["matches"])} for x in found]},ensure_ascii=False,indent=2))
