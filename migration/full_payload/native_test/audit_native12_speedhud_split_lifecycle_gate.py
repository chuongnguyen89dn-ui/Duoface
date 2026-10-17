#!/usr/bin/env python3
"""Read-only Native12 split lifecycle proof: method inventory and selected disassembly."""
from __future__ import annotations
import argparse,hashlib,json,re,subprocess,tempfile
from pathlib import Path
from audit_native12_license_class_xrefs import MachO,select_arm64,BINARIES,NATIVE12_SHA
from audit_native12_carplay_add_app_chain import methods,disassemble

CLASSES=("CBBridgeManager","CBWindow","CBBridgedSplitApp",
         "CBMultitaskingOverlayView","CBSplitContainerView","CBBridgeManagerDashboard")
SELECTORS=re.compile(r"current|active|visible|state|window|bridge|start|stop|deactiv|dismiss|show|hide|scene|split|app|layout|parent|present|container",re.I)
PIN="9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea"

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--deb",required=True,type=Path)
    p.add_argument("--out",required=True,type=Path)
    a=p.parse_args()
    assert hashlib.sha256(a.deb.read_bytes()).hexdigest()==NATIVE12_SHA
    with tempfile.TemporaryDirectory(prefix="duoface-split-gate-") as tmp:
        subprocess.run(["dpkg-deb","-x",str(a.deb),tmp],check=True)
        data=(Path(tmp)/BINARIES["DuoFaceDashboard"]).read_bytes()
    assert hashlib.sha256(data).hexdigest()==PIN
    mo=MachO(select_arm64(data))
    catalog=mo.classes()
    report={}
    for cls in CLASSES:
        assert cls in catalog,cls
        m=methods(mo,cls)
        filtered=[k for k in m if SELECTORS.search(k)]
        ordered=sorted(set(d["vm"] for d in m.values() if d["vm"]))
        details={}
        for selector in filtered:
            item=m[selector]
            vm=item["vm"]
            if re.search(r"init|window|activ|current|state|show|hide|start|stop|deactiv|bridge|layout|app",selector,re.I):
                limit=next((s for s in ordered if s>vm),vm+1600)
                sample=disassemble(mo,vm,min(limit,vm+4800))
                refs=[r for r in sample if "SEL_OR_LITERAL" in r or "DIRECT_STRING" in r]
                details[selector]={"address":hex(vm),"objc_type":item["type"],
                        "refs":refs[:120],"instructions":sample[:550]}
        report[cls]={"all_methods":sorted(m),"focused_selectors":filtered,
                      "focus_details":details}
    output={"status":"PINNED_NATIVE12_SPLIT_OWNER_LIFECYCLE_FORENSICS_READONLY",
        "native12_sha256":NATIVE12_SHA,"dashboard_sha256":PIN,
        "on_device_gate_proven":False,"hud_built":False,
        "classes":report}
    a.out.parent.mkdir(parents=True,exist_ok=True)
    a.out.write_text(json.dumps(output,ensure_ascii=False,indent=2)+"\n")
    print("NATIVE12_SPLIT_LIFECYCLE_ABI_READONLY_PASS")
    for cls,r in report.items():
        print("CLASS",cls,"METHODS",len(r["all_methods"]))
        print("FOCUSED",cls,r["focused_selectors"])
        for selector,item in r["focus_details"].items():
            if re.search(r"active|current|visible|stop|deactivate|requestStateChange|show",selector,re.I):
                print("FOCUSED_DETAILS",cls,selector,item["objc_type"],item["refs"][:12])
if __name__=="__main__":main()
