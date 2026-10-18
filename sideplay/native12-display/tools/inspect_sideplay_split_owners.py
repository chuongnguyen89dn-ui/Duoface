#!/usr/bin/env python3
"""READ-ONLY narrow split-pane class-selector owner map.

Reuse SHA-checked extracted dylib, QA's existing MachO parser, no new DEB scan,
no disassembly/decompilation of entire binaries. Only ObjC selector metadata.
"""
import hashlib,json,os,re,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
SOURCE=ROOT/"sideplay/extracted-1.0.4-1/rootfs/var/jb/Library/MobileSubstrate/DynamicLibraries/SidePlay.dylib"
INVENTORY=ROOT/"sideplay/audit/deb-1.0.4-1/inventory.json"
OUT=ROOT/"sideplay/native12-display/audit/SIDEPLAY_SPLIT_OWNER_SELECTORS.json"
raw=SOURCE.read_bytes()
inv=json.loads(INVENTORY.read_text())
original=next(x["sha256"] for x in inv if x.get("scope")=="rootfs" and x.get("path","").endswith("DynamicLibraries/SidePlay.dylib"))
assert hashlib.sha256(raw).hexdigest()==original
sys.path.insert(0,os.environ["SIDEPLAY_PARSER_DIR"])
from audit_native12_license_class_xrefs import MachO,select_arm64
from audit_native12_carplay_add_app_chain import methods
m=MachO(select_arm64(raw))
pattern=re.compile(r"(pane|split|divider|layout|frame|scale|slot|style|ratio|"
                   r"resize|width|height|ratio|size|rootView|window|grid|"
                   r"region|view|mode|drag|pan|touch|appArea)",re.I)
matches=[]
for name in m.classes():
    try: selectors=methods(m,name)
    except (AssertionError,IndexError,KeyError,ValueError):continue
    records=[{"selector":k,"imp":hex(v["vm"]),"type":v["type"]}
             for k,v in selectors.items() if pattern.search(k)]
    if records:
        matches.append({"class":name,"selectors":records,"count":len(selectors)})
OUT.parent.mkdir(parents=True,exist_ok=True)
OUT.write_text(json.dumps({"sha256":original,"source":"verified extracted original SidePlay.dylib arm64",
 "status":"STATIC_METHOD_DECLARATIONS_ONLY_NOT_EXECUTED","matches":matches},indent=2,ensure_ascii=False)+"\n")
print(json.dumps({"sha256":original,"classes":len(matches),"likely":[{"class":x["class"],"selectors":[a["selector"] for a in x["selectors"]][:28]} for x in matches if re.search("dash|split|pane|layout|ui|view",x["class"],re.I)][:65]},ensure_ascii=False))
