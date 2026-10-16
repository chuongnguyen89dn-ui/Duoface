#!/usr/bin/env python3
"""Read-only evidence for real Native12 CBWindow / CBBridgeManager split HUD owner.
No alteration of baseline, no installation, no device-runtime claim.
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

SOURCE_EXPECTED="9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea"
SELECTORS={
 "CBBridgeManager": [
    "+sharedInstanceIfExists", "+sharedInstance", "-window", "-init",
    "-requestStateChange:", "-loadNewAppFromCurrentRequest:", "-deactivateCurrentApp",
 ],
 "CBWindow":[
    "+activeCarPlayWindow", "+carPlayWindowScene",
    "-initWithAppFrame:", "-createWindows", "-show", "-resizeWindows",
    "-rootWindow", "-rootViewController", "-contentView", "-isVisible",
 ],
 "CBBridgedSplitApp":[
    "-startInParentViewController:", "-start", "-layoutSplitViews",
 ],
 "CBSplitContainerView":["-layoutSubviews"],
}
FOCUS=re.compile(r"CBWindow|CBBridgeManager|window|content|root|scene|display|setHidden|setAlpha|addSubview|setFrame|setWindow|isVisible|createWindows|show|resize|startInParent|split|render|UIApplication|UIScreen",re.I)
def main():
    p=argparse.ArgumentParser()
    p.add_argument("--deb",type=Path,required=True)
    p.add_argument("--out",type=Path,required=True)
    args=p.parse_args()
    assert hashlib.sha256(args.deb.read_bytes()).hexdigest()==NATIVE12_SHA, "pin mismatch"
    with tempfile.TemporaryDirectory(prefix="df12-hud-split-owner-") as tmp:
        subprocess.run(["dpkg-deb","-x",str(args.deb),tmp],check=True)
        raw=(Path(tmp)/BINARIES["DuoFaceDashboard"]).read_bytes()
    assert hashlib.sha256(raw).hexdigest()==SOURCE_EXPECTED,"Dashboard dylib changed"
    m=MachO(select_arm64(raw))
    classes=m.classes()
    outputs={}
    for cl,names in SELECTORS.items():
        assert cl in classes, "missing class "+cl
        catalog=methods(m,cl)
        ordered=sorted(set(v["vm"] for v in catalog.values() if v.get("vm")))
        observed={}
        for sel in names:
            assert sel in catalog, "missing "+cl+"."+sel
            info=catalog[sel]
            start=info["vm"]
            stop=next((v for v in ordered if v>start),start+2400)
            sample=disassemble(m,start,min(stop,start+4096))
            marked=[{"index":i,"line":line} for i,line in enumerate(sample)
                    if FOCUS.search(line) and ("SEL_OR_LITERAL" in line or "DIRECT_STRING" in line)]
            observed[sel]={
                "imp_vm":hex(start),"objc_type":info["type"],
                "function_limit_vm":hex(stop),
                "sampled_instructions":len(sample),
                "selector_or_string_refs":marked[:100],
                "disassembly":sample[:600],
            }
        outputs[cl]=observed
    report={
      "status":"NATIVE12_SPEED4SPLIT_OWNER_STATIC_FORENSICS_ONLY",
      "baseline_deb_sha256":NATIVE12_SHA,
      "dashboard_dylib_sha256":SOURCE_EXPECTED,
      "device_runtime_owner_verified":False,
      "injection_process_verified":False,
      "hud_visible_in_split":False,
      "limitation":"Static Mach-O methods prove API/branches but not which process constructs class, window scene or actual UI.",
      "methods":outputs,
    }
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(report["status"])
    for cl,group in outputs.items():
        for sel,m in group.items():
            hits=[r["line"].split("SEL_OR_LITERAL ")[-1] for r in m["selector_or_string_refs"]]
            print("METHOD",cl,sel,m["imp_vm"],m["objc_type"],"refs",hits[:20])
    print("NO_DEB_NO_SILEO_NO_DEVICE_TEST")
if __name__=="__main__":
    main()
