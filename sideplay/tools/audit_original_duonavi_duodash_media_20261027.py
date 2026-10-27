#!/usr/bin/env python3
"""STATIC ONLY: SHA-pinned original DuoNavi 1.0.4 and separate DuoDash 1.1.3
Fullscreen427 REPACK. No vendor code copied, run, patched or installed.
Method metadata and bounded callsite evidence; not a physical video benchmark.
"""
import argparse
import bisect
import hashlib
import io
import json
import os
import re
import subprocess
import sys
import tarfile
from pathlib import Path

PINS = {
    "duonavi104": "f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd",
    "duodash113_repack": "ea0d3bb8c8b9da2b45c3f158f390a7966419e84899f820d06f45cd51401fa465",
}
MEMBERS = {
    "duonavi104": "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoNaviDashboard.dylib",
    "duodash113_repack": "var/jb/usr/lib/TweakInject/DuoDash.dylib",
}
INTEREST = re.compile(
    r"scene|bridge|appview|viewport|ref(erence)?size|orientation|host|layout|"
    r"foreground|background|requestedmode|session|frame|video|split|"
    r"latch|crash|enable|scale|inject|fullscreen|dismiss|appstate",
    re.IGNORECASE,
)
SELECTED = {
    "duonavi104": {
      "CBBridgedUIAppView": ["updateLayout", "refreshSceneLayout",
          "updateSceneSettingsFrame", "calculateNativeSizeForSlotRect:",
          "setAudioOnlyBackgroundMode:", "dismiss"],
      "CBBridgeManager": ["renderSizeForBundleID:", "supportsInterfaceOrientation:forBundleID:",
          "requestStateChange:", "loadNewAppFromCurrentRequest:"],
      "CBBridgedSplitApp": ["layoutSplitViews", "handleDividerPan:isVertical:state:"],
    },
    "duodash113_repack": {
      "CNABUIApp": ["setBridgeState:width:height:orientation:"],
      "CNABSpringBoardObserver": ["onHostRequest:", "onHostRequestSplit:"],
      "DDz2": ["cnabBuildSceneHostForBid:displaySize:"],
      "DDz1": ["showLayoutPanes:natives:bids:"],
    },
}
def sha(b): return hashlib.sha256(b).hexdigest()
def extract(deb,member):
    stream=subprocess.run(["dpkg-deb","--fsys-tarfile",str(deb)],
                          check=True,stdout=subprocess.PIPE).stdout
    with tarfile.open(fileobj=io.BytesIO(stream),mode="r:") as tf:
        found=[m for m in tf if m.isfile() and m.name.lstrip("./")==member]
        if len(found)!=1: raise RuntimeError("not exactly one expected dylib: "+member)
        return tf.extractfile(found[0]).read()
def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--duonavi",type=Path,required=True)
    ap.add_argument("--duodash-repack",type=Path,required=True)
    ap.add_argument("--out",type=Path,required=True)
    args=ap.parse_args()
    root=os.environ.get("NATIVE_PARSER_DIR")
    if not root: raise RuntimeError("NATIVE_PARSER_DIR is required (verified first-party historical MachO parser)")
    sys.path.insert(0,root)
    from audit_native12_license_class_xrefs import MachO,select_arm64
    from audit_native12_carplay_add_app_chain import methods,disassemble
    report={
      "kind":"EXACT_INPUT_SHA_STATIC_MEDIA_BRIDGE_CALLGRAPH",
      "date":"2026-10-27",
      "bins":{},
      "not_tested":["real iOS16 Dopamine runtime", "YouTube/Facebook video",
                    "safety with other injected tweaks", "original stock DuoDash 1.1.3"],
      "not_modified":["vendor MachO","app code","SpringBoard","CarPlay","DEB","Sileo"],
    }
    binaries={"duonavi104":args.duonavi,"duodash113_repack":args.duodash_repack}
    for name,deb in binaries.items():
        data=deb.read_bytes()
        if sha(data)!=PINS[name]: raise AssertionError(name+" wrong DEB SHA256 "+sha(data))
        raw=extract(deb,MEMBERS[name])
        thin=select_arm64(raw)
        class _TaggedMachO(MachO):
            # Some REPACKED DuoDash arm64 metadata classlist pointers carry
            # high-bit rebasing tags. Require the stripped VM to map into the
            # MachO's OWN segment; never invent/scan an unrelated address.
            normalized=0
            def map(self,vm):
                try: return super().map(vm)
                except ValueError:
                    clean=vm & 0x0000FFFFFFFFFFFF
                    if clean==vm: raise
                    mapped=super().map(clean)
                    self.normalized+=1
                    return mapped
        m=_TaggedMachO(thin) if name=="duodash113_repack" else MachO(thin)
        classes=m.classes()
        perclass={}
        allstarts=set()
        for cl in classes:
            try:
                found=methods(m,cl)
                perclass[cl]=found
                allstarts.update((v["vm"] & 0x0000FFFFFFFFFFFF if name=="duodash113_repack" else v["vm"]) for v in found.values() if v.get("vm"))
            except (ValueError,KeyError,IndexError,AssertionError):
                continue
        starts=sorted(allstarts)
        selected=SELECTED[name].copy()
        if name=="duodash113_repack":
            # Dynamic metadata discovery ONLY. Don't invent absent obfuscated symbols.
            for cl in sorted(perclass):
                if not INTEREST.search(cl) or len(cl)>95: continue
                sels=[s.lstrip("+-") for s in perclass[cl] if INTEREST.search(s)]
                if sels and len(selected)<25: selected.setdefault(cl,sels[:12])
        result={
          "package_sha256":sha(data),"dylib_member":MEMBERS[name],
          "dylib_sha256":sha(raw),"plain_arm64_sha256":sha(thin),
          "objc_class_count":len(classes),"objc_parsed_class_count":len(perclass),
          "repacked_classlist_tagged_vm_normalizations":getattr(m,"normalized",0),
          "class_candidates":[cl for cl in sorted(perclass) if
                              ("CNAB" in cl or "DDz" in cl or "CBBridge" in cl or "CBBridgedUIApp" in cl)][:85],
          "methods":[],"missing":[]
        }
        for cl,targets in selected.items():
            if cl not in perclass:
                result["missing"].append("class "+cl)
                continue
            byname=perclass[cl]
            for target in targets:
                match=byname.get("-"+target) or byname.get("+"+target)
                if not match:
                    result["missing"].append(cl+"."+target)
                    continue
                # FAT repack ObjC metadata uses 0x20/0x80 high-tagged
                # IMP pointers, not actual 64-bit disassembly addresses.
                rawvm=match["vm"]
                vm=(rawvm & 0x0000FFFFFFFFFFFF) if name=="duodash113_repack" else rawvm
                hi=bisect.bisect_right(starts,vm)
                nextvm=starts[hi] if hi<len(starts) else vm+4096
                # Method entry is verified by ObjC relative/absolute metadata;
                # bound is next Objective-C IMP, not a guaranteed function end.
                limit=min(nextvm,vm+0x3000)
                ins=disassemble(m,vm,limit)
                marker=[]
                for i,line in enumerate(ins):
                    if INTEREST.search(line) and "SEL_OR_LITERAL" in line:
                        marker.append(line[:210])
                # A function calling another matching method can be proven by
                # instruction entry/call PC, not by a loose string occurrence.
                callsites=[x[:165] for x in ins if
                           re.search(r"\bbl\s+[#0-9a-fx]+",x)][:35]
                focus=(name=="duodash113_repack" and (cl,target) in {
                    ("CNABUIApp","setBridgeState:width:height:orientation:"),
                    ("CNABSpringBoardObserver","onHostRequest:"),
                    ("CNABSpringBoardObserver","onHostRequestSplit:"),
                    ("DDz2","cnabBuildSceneHostForBid:displaySize:"),
                    ("DDz1","showLayoutPanes:natives:bids:"),
                })
                result["methods"].append({
                    "class":cl,"selector":target,"imp":hex(vm),
                    "raw_tagged_method_pointer":hex(rawvm) if rawvm!=vm else None,
                    "full_bounded_ARM64":ins if focus else None,
                    "objc_type":match.get("type"),
                    "bounded_next_imp":hex(nextvm),"extracted_instructions":len(ins),
                    "truncated":nextvm>limit or len(ins)>=1400,
                    "method_entry":ins[0][:130] if ins else None,
                    "semantic_selector_refs":marker[:70],
                    "callsites":callsites[:24],
                    "no_claim_of_execution":True
                })
        report["bins"][name]=result
        print(name,"DEB_SHA_OK",sha(data),"classes",len(classes),
              "selected",len(result["methods"]),"missing",len(result["missing"]))
        for obj in result["methods"]:
            if (name=="duonavi104" and obj["class"]=="CBBridgedUIAppView") or (
                name=="duodash113_repack" and obj["selector"] in
                ["setBridgeState:width:height:orientation:","onHostRequest:","onHostRequestSplit:",
                 "cnabBuildSceneHostForBid:displaySize:","showLayoutPanes:natives:bids:"]):
                print("PROOF",name,obj["class"],obj["selector"],obj["imp"],
                      "refs",obj["semantic_selector_refs"][:9])
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    print("STATIC_SHA_VERIFIED_MEDIA_BRIDGE_EVIDENCE",args.out)
if __name__=="__main__": main()
