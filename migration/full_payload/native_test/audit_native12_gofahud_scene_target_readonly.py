#!/usr/bin/env python3
"""Read-only owner / UIWindowScene map to design a GOFAHUD-style DuoFace overlay.

Reads exact SHA-pinned Native12 from repository; never runs or patches jailbreak
binary, never builds a package. Static Mach-O selector references are NOT
proof of process runtime, window presentation or device UI.
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

TARGETS={
 "CBWindow":[
 "+carPlayWindowScene","+carPlayUIScreen","+activeCarPlayWindow",
 "-initWithAppFrame:","-createWindows","-show","-hide:","-rootWindow",
 "-isVisible","-destroyWindows"],
 "CBBridgeManager":[
 "+sharedInstance","+sharedInstanceIfExists","-init","-window",
 "-requestStateChange:","-loadNewAppFromCurrentRequest:"],
 "CBBridgeManagerDashboard":[
 "+sharedInstance","-init","-bridgeDidActivate:","-bridgeDidDeactivate",
 "-startBridging:withCompletion:","-stopBridgingWithCompletion:",
 "-handleStateDict:","-requestActivation:","-activated"],
 "CBBridgedSplitApp":[
 "-startInParentViewController:","-start","-layoutSplitViews"],
}
SENSITIVE_SELECTORS=re.compile(
 r"sharedInstance|connectedScenes|scene|screen|CarPlay|"
 r"UIRootSceneWindow|rootWindow|rootViewController|windowLevel|"
 r"setHidden:|makeKeyAndVisible|show|activate|deactivate|"
 r"isVisible|root|didConnect|application|setWindowScene:|"
 r"UIApplication|Dashboard|UIApplicationDelegate|currentApp|"
 r"view|addSubview:|bundle|isKindOfClass:",re.I)
BRANCH_STRINGS=(
  "[DuoFace] Initializing DashBoard hooks in process:",
  "[DuoFace] Initializing SpringBoard hooks...",
  "SpringBoard finished launching, safely initializing CBBridgeManager",
  "Initializing DashBoard Modular Hooks",
  "Initializing SpringBoard Modular Hooks",
)
def main():
    p=argparse.ArgumentParser()
    p.add_argument("--deb",type=Path,required=True)
    p.add_argument("--out",type=Path,required=True)
    args=p.parse_args()
    rawdeb=args.deb.read_bytes()
    digest=hashlib.sha256(rawdeb).hexdigest()
    assert digest==NATIVE12_SHA,"native12 not exact"
    with tempfile.TemporaryDirectory(prefix="df12-gofahud-scene-readonly-") as td:
        subprocess.run(["dpkg-deb","-x",str(args.deb),td],check=True)
        raw=(Path(td)/BINARIES["DuoFaceDashboard"]).read_bytes()
    m=MachO(select_arm64(raw))
    allclasses=m.classes()
    result={}
    for cls,selectors in TARGETS.items():
        assert cls in allclasses,"missing class "+cls
        cat=methods(m,cls)
        ordered=sorted({info["vm"] for info in cat.values() if info.get("vm")})
        result[cls]={}
        for sel in selectors:
            assert sel in cat,"missing "+cls+"."+sel
            d=cat[sel]
            start=d["vm"]
            stop=next((v for v in ordered if v>start),start+2400)
            scope=10000 if (cls=="CBWindow" and sel=="+carPlayWindowScene") else 4800
            asm=disassemble(m,start,min(stop,start+scope))
            result[cls][sel]={
              "address":hex(start),"objc_type":d["type"],"instruction_count":len(asm),
              "selector_refs":[x for x in asm if "SEL_OR_LITERAL" in x and SENSITIVE_SELECTORS.search(x)],
              "calls":[x for x in asm if re.search(r"\\b(?:bl|blr|br)\\b",x)][:110],
              "code_head":asm[:min(len(asm),115)],
            }
    # Existing audit/disassembly pinned to same immutable SHA proves these
    # constructor entrypoints and process-specific initialization branches.
    entrypoints={}
    for name,at,size in [
        ("rootless_constructor_branch",0x62e0,960),
        ("dashboard_hook_modules",0x2ec644,72),
        ("springboard_hook_modules",0x2ec60c,72),
        ("springboard_manager_after_launch",0x2ca140,64),
    ]:
        try:
            code=disassemble(m,at,at+size)
            entrypoints[name]={"address":hex(at),"code":code[:175]}
        except Exception as e:
            entrypoints[name]={"error":str(e)}
    # +[CBBridgeManagerDashboard sharedInstance] and activation callbacks use
    # direct dyld ObjC selector references; identify setter without guessing.
    activation_selrefs={}
    for addr in (0x37ed80,0x37eee8,0x37eef0,0x37d518,0x37e398):
        try:
            ptr=m.ptr(addr)
            name=m.cstr(ptr)
            activation_selrefs[hex(addr)]={"raw_ptr":hex(ptr),"selector":name}
        except Exception as e:
            activation_selrefs[hex(addr)]={"error":type(e).__name__}
    report={
       "status":"NATIVE12_GOFAHUD_SCENE_OWNER_STATIC_ONLY",
       "native12_sha256":digest,
       "dashboard_dylib_sha256":hashlib.sha256(raw).hexdigest(),
       "process_runtime_seen":False,
       "actual_scene_verified":False,
       "overlay_created":False,
       "deb_built":False,
       "device_tested":False,
       "limits":"Method ABI, static branches and potential UIWindowScene sourcing only",
       "known_initializer_literals":list(BRANCH_STRINGS),
       "branch_entries":entrypoints,
       "dashboard_activation_selrefs":activation_selrefs,
       "classes":result,
    }
    assert result["CBWindow"]["+carPlayWindowScene"]["instruction_count"]>50
    assert result["CBBridgeManager"]["+sharedInstanceIfExists"]["instruction_count"]>0
    assert result["CBBridgeManagerDashboard"]["+sharedInstance"]["instruction_count"]>0
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print("NATIVE12_GOFAHUD_SCENE_OWNER_STATIC_ONLY_PASS")
    print("sha256",digest)
    for cl,group in result.items():
        for sel,entry in group.items():
            print("METHOD",cl,sel,entry["address"],
                  "SCENE_SELREFS",entry["selector_refs"][:26],
                  "CALL_COUNT",len(entry["calls"]))
    print("DEVICE_SCENE_NOT_YET_VERIFIED; NO_DEB_OR_DEPLOY")
if __name__=="__main__":
    main()
