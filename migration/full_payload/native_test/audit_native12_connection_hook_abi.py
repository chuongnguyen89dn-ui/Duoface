#!/usr/bin/env python3
"""Read-only exact ObjC metadata signature inventory for DuoFace connection hooks.
Does not call a hook or mutate native12. Used to prevent ABI guessing.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
from audit_native12_license_class_xrefs import MachO, select_arm64, BINARIES, NATIVE12_SHA

TARGETS = {
    "DuoFaceUI": {
        "CBGeneralSettingsViewController": {
            "-autoLaunchToggleChanged:", "-autoLaunchOnConnect",
            "-setAutoLaunchOnConnect:", "-loadPreferences", "-savePreferences"},
    },
    "DuoFaceDashboard": {
        "CBBridgeManager": {
            "-handleCarPlayConnectionChanged:", "-effectiveAutoLaunchBundleID",
            "-terminateApplicationWithBundleID:", "-deactivateCurrentApp",
            "-terminateAllBridgedApplications"},
        "CBBridgeManagerDashboard": {"-handleStateDict:", "-bridgeDidActivate:",
                                     },
        "CBDashboardSettings": {"-autoLaunchOnConnect", "-setAutoLaunchOnConnect:",
                                "-autoLaunchBundleID", "-setAutoLaunchBundleID:"},
    },
}

def inspect_bin(name, raw):
    mo=MachO(select_arm64(raw))
    classes=mo.classes()
    out={}
    missing=[]
    for cls,selectors in TARGETS[name].items():
        if cls not in classes: raise AssertionError("class absent "+cls)
        ptr=classes[cls]["class_ptr"]
        methods={}
        for kind,obj in (("-",ptr),("+",mo.ptr(ptr))):
            head=mo.ptr((mo.ptr(obj+32)&~7)+32)
            if not head:continue
            flags,count=mo.p32(head),mo.p32(head+4)
            assert count<500
            relative=bool(flags & 0x80000000)
            stride=12 if relative else 24
            for j in range(count):
                e=head+8+j*stride
                if relative:
                    nm=e+mo.pi32(e)
                    selvm=nm if flags & 0x40000000 else mo.ptr(nm)
                    typ=e+4+mo.pi32(e+4)
                    impl=e+8+mo.pi32(e+8)
                else:
                    selvm=mo.ptr(e);typ=mo.ptr(e+8);impl=mo.ptr(e+16)
                selector=kind+mo.cstr(selvm)
                if selector not in selectors:continue
                if not impl:raise AssertionError("null implementation for "+cls+selector)
                value=mo.cstr(typ)
                if not value:raise AssertionError("missing type encoding for "+cls+selector)
                methods[selector]={"type_encoding":value,"imp_vm":hex(impl),
                                   "relative_method_list":relative}
        absent=sorted(selectors-set(methods))
        if absent:missing.extend(cls+"::"+x for x in absent)
        out[cls]=methods
    if missing:raise AssertionError("missing required selectors "+str(missing))
    return {"sha256":hashlib.sha256(raw).hexdigest(),
            "arm64_slice_sha256":hashlib.sha256(mo.data).hexdigest(),
            "classes":out}

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--deb",required=True,type=Path)
    p.add_argument("--out",required=True,type=Path)
    a=p.parse_args()
    if hashlib.sha256(a.deb.read_bytes()).hexdigest()!=NATIVE12_SHA:
        raise SystemExit("native12 pinned SHA256 mismatch")
    with tempfile.TemporaryDirectory(prefix="df12-connect-abi-") as temp:
        subprocess.run(["dpkg-deb","-x",str(a.deb),temp],check=True)
        objs={name:inspect_bin(name,(Path(temp)/path).read_bytes())
              for name,path in BINARIES.items()}
    total=sum(len(m) for b in objs.values() for m in b["classes"].values())
    assert total==5+5+2+4, total
    out={"status":"NATIVE12_ACTUAL_CONNECTION_OBJC_ABI_READONLY",
         "source_deb_sha256":NATIVE12_SHA,"selectors_examined":total,
         "actual_carplay_event_runtime_verified":False,"used_to_patch_binary":False,
         "types_must_be_reviewed_before_installing_any_hook":True,"binaries":objs}
    a.out.parent.mkdir(parents=True,exist_ok=True)
    a.out.write_text(json.dumps(out,ensure_ascii=False,indent=2)+"\n")
    print(json.dumps({"status":out["status"],"selector_count":total,
       "types":{bin:{cl:{sel:ob["type_encoding"] for sel,ob in methods.items()}
             for cl,methods in b["classes"].items()} for bin,b in objs.items()}},
       indent=2))
if __name__=="__main__":
    main()
