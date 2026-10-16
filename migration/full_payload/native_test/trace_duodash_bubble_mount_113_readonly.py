#!/usr/bin/env python3
"""DuoDash 1.1.3+fullscreen1 reference: locate bubble creation/mount/lifecycle
by complete class method inventory plus bounded ARM64 disassembly.
READONLY. Does not infer actual CarPlay injection runtime from ABI alone.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import plistlib
import re
import subprocess
import tempfile
from pathlib import Path
from audit_duodash_perf_thermal_113 import NormalizedMachO, fat_slices, PINNED_GIT_BLOB
from audit_native12_carplay_add_app_chain import methods, disassemble

SHA256="ea0d3bb8c8b9da2b45c3f158f390a7966419e84899f820d06f45cd51401fa465"
SELECTOR_RE=re.compile(r"bubble|pane|host|window|view|controller|layout|open|split|init|show|hide|start|stop|connect|attach|scene|root|render|refresh|sync|display|speed|nav|setting|snap|rebuild|mount|toggle|reconcile",re.I)
HINT_RE=re.compile(r"addSubview:|insertSubview:|bringSubviewToFront:|initWithFrame:|CNABBubbleView|paneRect|makeKeyAndVisible|setHidden:|setAlpha:|windowLevel|windowScene|rootViewController|setView:|setFrame:|startSpeedReadout|stopSpeedReadout|bubblePane|bubblePosition|bubble|Bubble|setNeedsLayout|layoutSubviews|shared|carPlay",re.I)

def audit(root):
    dy=root/"var/jb/usr/lib/TweakInject/DuoDash.dylib"
    assert dy.is_file(),dy
    raw=dy.read_bytes()
    slices=fat_slices(raw)
    out={"dylib_sha256":hashlib.sha256(raw).hexdigest(),"plist_filters":[],"architecture":{}}
    for path in sorted((root/"var/jb").rglob("*DuoDash*.plist")):
        try:
            q=plistlib.loads(path.read_bytes())
            out["plist_filters"].append({"path":path.relative_to(root).as_posix(),"filter":q.get("Filter"),"keys":list(q.keys())[:18]})
        except Exception as e:
            out["plist_filters"].append({"path":path.relative_to(root).as_posix(),"error":type(e).__name__})
    for arch,data in slices.items():
        if arch not in ("arm64","arm64e"): continue
        obj=NormalizedMachO(data)
        all_classes=obj.classes()
        entries={}
        for cl in sorted(all_classes):
            try: catalog=methods(obj,cl)
            except Exception as e:
                entries[cl]={"error":type(e).__name__};continue
            ordered=sorted({int(q["vm"]) for q in catalog.values() if q.get("vm")})
            items={}
            for sel,q in sorted(catalog.items()):
                if not SELECTOR_RE.search(sel): continue
                begin=int(q["vm"]); end=next((v for v in ordered if v>begin),begin+1200)
                asm=disassemble(obj,begin,min(end,begin+(5200 if cl in ("DDz4","DDz1","DDz2") else 1800)))
                hints=[s for s in asm if ("SEL_OR_LITERAL" in s or "DIRECT_STRING" in s) and HINT_RE.search(s)]
                if not (HINT_RE.search(sel) or hints or cl in ("DDz4","DDz1","DDz2") or (cl=="DDz3" and "Bubble" in sel)): continue
                items[sel]={
                    "imp":hex(begin),"abi":q.get("type"),
                    "refs":hints[:65],
                    "disasm":asm[:1200] if (hints or cl in ("DDz4","DDz1","DDz2","DDz3") or re.search("bubble|pane|host|window|view|controller|split",cl,re.I)) else [],
                }
            entries[cl]={"method_count":len(catalog),"all_methods":sorted(catalog),
                        "interesting":items}
        out["architecture"][arch]={"classes":entries,"total_classes":len(all_classes)}
    return out

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--deb",type=Path,required=True)
    ap.add_argument("--out",type=Path,required=True)
    a=ap.parse_args()
    original=a.deb.read_bytes()
    assert hashlib.sha256(original).hexdigest()==SHA256
    assert subprocess.check_output(["git","hash-object",str(a.deb)],text=True).strip()==PINNED_GIT_BLOB
    with tempfile.TemporaryDirectory(prefix="duodash-bubble-owner-chain-") as td:
        subprocess.run(["dpkg-deb","-x",str(a.deb),td],check=True)
        report=audit(Path(td))
    report.update({
      "status":"DUODASH_NAVBUBBLE_MOUNT_STATIC_CHAIN_READONLY",
      "package_sha256":SHA256,
      "git_blob":PINNED_GIT_BLOB,
      "source_variant":"DuoDash 1.1.3+fullscreen1 from DauDat-CarPlay; not proven stock byte-identical",
      "runtime_visible_on_carplay_tested":False,
      "modified_deb":False,
      "sileo_touched":False,
      "scope":"static class-method references and bounded instructions, not definitive ObjC control flow",
    })
    assert report["architecture"].get("arm64",{}).get("total_classes",0)>=35
    assert "CNABBubbleView" in report["architecture"]["arm64"]["classes"]
    a.out.parent.mkdir(parents=True,exist_ok=True)
    a.out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n")
    print("DUODASH_NAVBUBBLE_MOUNT_STATIC_CHAIN_READONLY_PASS")
    print("INJECTION_FILTERS",report["plist_filters"])
    for cl,details in report["architecture"]["arm64"]["classes"].items():
        interesting=details.get("interesting",{})
        if interesting or "CNAB" in cl:
            print("CLASS",cl,"METHODS",details.get("method_count"),
                  "INTERESTING",list(interesting)[:35])
    print("NO_DEB_NO_DEVICE_TEST")

if __name__=="__main__":main()
