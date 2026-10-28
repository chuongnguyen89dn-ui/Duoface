#!/usr/bin/env python3
"""Read-only original Native12 HUD8 DEB scan: YouTube scene owner and rotation.

Inspect actual SHA-pinned original MACH-O, not selector-string guesses. Inspect
native host, app-injected Dashboard, and fullscreen routing across eight images.
Never redistribute binaries, copy licensing, change DuoFace, or claim device ACK.
"""
from __future__ import annotations
import argparse
import bisect
import hashlib
import json
import plistlib
import re
import subprocess
import sys
import tempfile
from pathlib import Path

DEB_SHA="2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad"
INDEX_GIT_BLOB="efa45df59bc3c16887cc979bf3aedc0c93c92111"
EXPECTED={
    "DuoFaceDashboard.dylib":"9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea",
    "DuoFaceFullscreenBridge.dylib":"0bcd172dedbbffe7ad5d549770c1c1769323e21b0127528a661bbe144c10f3fe",
}
SCAN_IMAGES=("DuoFaceDashboard.dylib","DuoFaceFullscreenBridge.dylib","DuoFaceUI","DuoFaceVisualHook.dylib")
FOCUS={
    "CBBridgedUIAppView":(
        "refreshSceneLayout","updateLayout","updateSceneSettingsFrame",
        "updateSceneFrame","layoutSubviews"
    ),
    "CBBridgeManager":(
        "renderSizeForBundleID:","shouldBridge:",
        "supportsInterfaceOrientation:forBundleID:",
        "sendStateToApp:shouldBridge:"
    )
}
SELECTOR_NEEDLES={
    "main_scene_hook":"_mainSceneSupportsInterfaceOrientation:",
    "interface_rotation":"interfaceOrientation",
    "orientation_write":"setInterfaceOrientation:",
    "app_orientation_feedback":"clientSettings",
    "app_scene_feedback":"scene:didUpdateSettingsWithDiff:previousSettings:",
    "ui_view_rotation":"_setRotatableViewOrientation:",
    "ui_supported_orientations":"supportedInterfaceOrientations",
    "ui_geometry":"requestGeometryUpdate",
    "ui_scene":"connectedScenes",
    "fullscreen":"fullscreen",
    "video":"AVPlayer",
    "scene_handle":"sceneHandle",
    "update_settings":"updateSettingsWithBlock:",
    "scene_reference":"setContentReferenceSize:",
    "scene_owner":"isUIAppBridging",
    "process_name":"processName",
    "notification":"NSDistributedNotificationCenter",
    "orientation_notification":"orientation",
    "youtube":"com.google.ios.youtube",
}
DIRECT_RANGES={
    "main_scene_orientation_policy":(0x2c8b4c,0x2c8ca4),
    "two_arg_reference_policy":(0x2c895c,0x2c8a50),
    "three_arg_reference_policy":(0x2c8a50,0x2c8b4c),
    "host_hook_registration":(0x2c7c40,0x2c7f00),
    "scene_update_handler":(0x2c7e08,0x2c8410),
}
INSN=re.compile(r"^\s*(?:0x)?([0-9a-fA-F]+):\s+(.+)$")
BL=re.compile(r"\bbl\s+(0x[0-9a-fA-F]+)")
def sha(a):return hashlib.sha256(a).hexdigest()
def git_blob(a):return hashlib.sha1(b"blob "+str(len(a)).encode()+b"\0"+a).hexdigest()
def robust_json(a):
    if isinstance(a,dict):return {str(k):robust_json(v) for k,v in a.items()}
    if isinstance(a,(list,tuple)):return [robust_json(v) for v in a]
    if isinstance(a,bytes):return "<binary-"+str(len(a))+"-bytes>"
    if isinstance(a,(str,int,float,bool)) or a is None:return a
    return str(a)
def owner_for(pc, starts, entries):
    ix=bisect.bisect_right(starts,pc)-1
    if ix<0:return {"status":"NO_OBJC_METHOD_IN_RANGE"}
    start=starts[ix]
    if pc-start>0x2800:return {"status":"NEAREST_OBJC_TOO_FAR","nearest":hex(start)}
    m=entries[start]
    return {"class":m["class"],"selector":m["selector"],
            "imp":hex(start),"distance_from_imp":hex(pc-start),
            "attribution":"NEAREST_IMP_ONLY_NOT_PROVEN_EXTENT"}
def segment(lines,lo,hi,limit=380):
    hits=[{"pc":hex(x["pc"]),"asm":x["asm"]} for x in lines if lo<=x["pc"]<hi]
    return {"first_pc":hex(lo),"last_exclusive":hex(hi),
            "matching_arm64_instructions":len(hits),
            "truncated":len(hits)>limit,"arm64":hits[:limit]}
def audit_objdump(binary, index, out, expected):
    raw=binary.read_bytes()
    h=sha(raw)
    if expected and h!=expected:raise RuntimeError(binary.name+" SHA256 mismatch "+h)
    exe=out/("thin-"+binary.name)
    import os
    sys.path.insert(0,os.environ["NATIVE_PARSER_DIR"])
    from audit_native12_license_class_xrefs import select_arm64
    thin=select_arm64(raw)
    exe.write_bytes(thin)
    tool=os.getenv("OBJDUMP","llvm-objdump-18")
    result=subprocess.run([tool,"--macho","--disassemble","--no-show-raw-insn",str(exe)],
                          capture_output=True,text=True,encoding="utf-8",errors="replace")
    if result.returncode:raise RuntimeError("llvm-objdump "+binary.name+" failed "+result.stderr[-1500:])
    lines=[]
    for s in result.stdout.splitlines():
        m=INSN.match(s)
        if m: lines.append({"pc":int(m.group(1),16),"asm":m.group(2).strip()})
    if not lines:raise RuntimeError("No original arm64 disassembly: "+binary.name)
    entries={int(x["imp"],16):x for x in index["objc_methods"]}
    starts=sorted(entries)
    # Closest ObjC IMP is a hint only: function starts and C/block helpers also exist.
    xrefs={}
    for kind,needle in SELECTOR_NEEDLES.items():
        needle_l=needle.lower()
        selected=[i for i,x in enumerate(lines) if needle_l in x["asm"].lower()
                  and ("Objc" in x["asm"] or "literal" in x["asm"] or "symbol" in x["asm"]
                       or "cfstring" in x["asm"].lower())]
        windows=[]
        for i in selected[:36]:
            x=lines[i]
            low=max(0,i-12); high=min(len(lines),i+14)
            window=lines[low:high]
            windows.append({
                "pc":hex(x["pc"]),"asm":x["asm"],
                "closest_objc_imp":owner_for(x["pc"],starts,entries),
                "arm64_window":[{"pc":hex(y["pc"]),"asm":y["asm"]} for y in window]
            })
        xrefs[kind]={"total_annotated_original_arm64_xrefs":len(selected),
                     "windows":windows,"truncated":len(selected)>len(windows)}
    focus=[]
    for m in index["objc_methods"]:
        if m["selector"] not in FOCUS.get(m["class"],()):continue
        start=int(m["imp"],16)
        pos=bisect.bisect_right(starts,start)
        next_imp=starts[pos] if pos<len(starts) else start+0x1800
        end=min(next_imp,start+0x1400)
        if start>=end:continue
        body=segment(lines,start,end,limit=380)
        actual_calls=[]
        for inst in body["arm64"]:
            bl=BL.search(inst["asm"])
            if not bl:continue
            dst=int(bl.group(1),16)
            item={"callsite":inst["pc"],"branch_to":hex(dst)}
            if dst in entries:
                item["direct_objc_imp"]={"class":entries[dst]["class"],
                                         "selector":entries[dst]["selector"]}
            actual_calls.append(item)
        focus.append({"class":m["class"],"selector":m["selector"],
                      "imp":hex(start),"next_objc_imp":hex(next_imp),
                      "objc_type":m["type"],"direct_bl_edges":actual_calls[:80],
                      "bounded_body":body})
    extra={}
    if binary.name=="DuoFaceDashboard.dylib":
        for label,(lo,hi) in DIRECT_RANGES.items():
            extra[label]=segment(lines,lo,hi,limit=380)
    return {"sha256":h,"arm64_sha256":sha(thin),"method_index_count":len(index["objc_methods"]),
            "total_arm64_instructions":len(lines),"xrefs":xrefs,
            "focused_original_implementations":focus,
            "verified_historical_hook_ranges":extra}

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--native12",required=True,type=Path)
    ap.add_argument("--method-index",required=True,type=Path)
    ap.add_argument("--out",required=True,type=Path)
    a=ap.parse_args()
    if sha(a.native12.read_bytes())!=DEB_SHA:raise RuntimeError("Original Native12 DEB pin mismatch")
    ib=a.method_index.read_bytes()
    if git_blob(ib)!=INDEX_GIT_BLOB:raise RuntimeError("Original method index blob mismatch")
    index=json.loads(ib)
    with tempfile.TemporaryDirectory(prefix="duoface-native12-youtube-proof-") as tmp:
        root=Path(tmp)/"payload"
        subprocess.run(("dpkg-deb","-x",str(a.native12),str(root)),check=True)
        plist_filters={}
        for f in sorted(root.rglob("*.plist")):
            if not f.name.startswith("DuoFace"):continue
            try:
                d=plistlib.loads(f.read_bytes())
                if isinstance(d,dict) and "Filter" in d:
                    plist_filters[str(f.relative_to(root))]=robust_json(d["Filter"])
            except (ValueError,TypeError,plistlib.InvalidFileException):pass
        result={
            "status":"VERIFIED_SHA_PINNED_NATIVE12_ORIGINAL_ARM64_NOT_RUNTIME",
            "original_deb_sha256":DEB_SHA,
            "original_abi_index_blob":INDEX_GIT_BLOB,
            "device_youtube_orientation_fixed":False,
            "source":"Native12 independent HUD8 gold original only, NOT DuoFace .86",
            "original_injection_filters":plist_filters,
            "images":{},"notice":[
                "Only original Native12 DEB used, no other vendor substituted",
                "Original ObjC method nearest-owner and objdump message annotations are not receiver proof",
                "DuoFace .86, Google Maps, Dock and live device were not modified or tested",
                "Original company licensing and protected binaries are not copied"
            ]
        }
        for binname in SCAN_IMAGES:
            matches=[x for x in root.rglob(binname) if x.is_file()]
            if len(matches)!=1:raise RuntimeError("Expected one original Mach-O "+binname+
                                                  " found "+str(len(matches)))
            idx=[x for x in index["native12"] if x["filename"]==binname]
            if len(idx)!=1:raise RuntimeError("No exact original method index "+binname)
            entry=audit_objdump(matches[0],idx[0],Path(tmp),EXPECTED.get(binname))
            result["images"][binname]=entry
            print("NATIVE12_ORIGINAL_IMAGE",binname,"methods",entry["method_index_count"],
                  "arm64",entry["total_arm64_instructions"],"sha",entry["sha256"],flush=True)
            for kind in ("interface_rotation","orientation_write","app_orientation_feedback",
                         "ui_geometry","fullscreen","youtube","process_name","notification"):
                print("NATIVE12_XREF",binname,kind,entry["xrefs"][kind]
                      ["total_annotated_original_arm64_xrefs"],flush=True)
        assert any("com.google.ios.youtube" in json.dumps(p)
                   for p in result["original_injection_filters"].values()),"Native12 YouTube filter missing"
        assert result["images"]["DuoFaceDashboard.dylib"]["verified_historical_hook_ranges"]["main_scene_orientation_policy"]["matching_arm64_instructions"]>0
        a.out.parent.mkdir(parents=True,exist_ok=True)
        a.out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf8")
        print("NATIVE12_YOUTUBE_ORIENTATION_ORIGINAL_PROOF",a.out)
if __name__=="__main__":main()
