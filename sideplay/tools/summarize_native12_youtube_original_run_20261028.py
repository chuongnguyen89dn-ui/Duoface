#!/usr/bin/env python3
"""Reduce exact SHA-pinned original Native12 ARM64 evidence to audit summary."""
import hashlib,json
from pathlib import Path
ROOT=Path("sideplay/audit/native12-083-rotation-20261028")
SOURCE=ROOT/"NATIVE12_ORIGINAL_YOUTUBE_ROTATION_RUN_40647306779.json"
OUT=ROOT/"NATIVE12_ORIGINAL_YOUTUBE_ROTATION_ANALYSIS_20261028.json"
DOC=ROOT/"NATIVE12_ORIGINAL_YOUTUBE_ROTATION_ANALYSIS_20261028.md"
BLOB_SHA="b894fb893c3da3a38ad035c7115fc981e10fcc00"
DEB="2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad"
DASH="9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea"
def bh(data):return hashlib.sha1(b"blob "+str(len(data)).encode()+b"\0"+data).hexdigest()
raw=SOURCE.read_bytes()
if bh(raw)!=BLOB_SHA:raise RuntimeError("Wrong original evidence Git blob: "+bh(raw))
d=json.loads(raw)
assert d["status"]=="VERIFIED_SHA_PINNED_NATIVE12_ORIGINAL_ARM64_NOT_RUNTIME"
assert d["original_deb_sha256"]==DEB
assert d["images"]["DuoFaceDashboard.dylib"]["sha256"]==DASH
refs=("main_scene_hook","interface_rotation","orientation_write","app_orientation_feedback",
      "ui_geometry","ui_scene","fullscreen","video","scene_handle","update_settings",
      "scene_reference","scene_owner","notification","orientation_notification","youtube")
images={}
for name,img in d["images"].items():
    images[name]={
      "sha256":img["sha256"],"objc_methods":img["method_index_count"],
      "arm64_instructions":img["total_arm64_instructions"],
      "xrefs":{key:{"count":img["xrefs"][key]["total_annotated_original_arm64_xrefs"],
         "first8":[{"pc":w["pc"],"asm":w["asm"],"nearest":w["closest_objc_imp"]}
                   for w in img["xrefs"][key]["windows"][:8]]}for key in refs},
      "focused_methods":[{
         "class":m["class"],"selector":m["selector"],"imp":m["imp"],
         "instructions":m["bounded_body"]["matching_arm64_instructions"],
         "bl":m["direct_bl_edges"][:18],
         "selected":[x for x in m["bounded_body"]["arm64"]
             if any(k in x["asm"] for k in ("selector ref:","cfstring ref:",
                "NSSelectorFromString","bl\t","cmp\t","b.ne\t","b.eq\t"))][:28]
         }for m in img["focused_original_implementations"]]
      }
hooks=d["images"]["DuoFaceDashboard.dylib"]["verified_historical_hook_ranges"]
patches={k:{"lo":v["first_pc"],"end":v["last_exclusive"],
             "count":v["matching_arm64_instructions"],"arm64":v["arm64"][:100]}
    for k,v in hooks.items()}
assert all(v["count"]>0 for v in patches.values())
out={
"source":"actual verified Native12 original DEB HUD8 only",
"source_deb_sha256":DEB,
"source_dashboard_sha256":DASH,
"source_git_blob":BLOB_SHA,
"source_sha256":hashlib.sha256(raw).hexdigest(),
"injection_filters":d["original_injection_filters"],
"images":images,"dashboard_hook_arm64":patches,
"limits":"Static original Mach-O. ObjC annotations may misattribute dynamic receiver. No iPhone video test or DuoFace app fix."}
OUT.write_text(json.dumps(out,indent=2,ensure_ascii=False)+"\n")
lines=["# Native12 original HUD8 — YouTube scene orientation, ARM64 facts",
"",
"Original DEB SHA256: "+DEB,
"Original Dashboard SHA256: "+DASH,
"Evidence run: https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40647306779 (SUCCESS).",
"Input original immutable Git blob: "+BLOB_SHA,
"Scope: original Native12 only, not SidePlay. Original DEB is read-only.",
"",
"## Original app/process injection filters"]
for path,f in out["injection_filters"].items():
    lines.append("- "+path+": "+json.dumps(f,sort_keys=True,ensure_ascii=False))
lines+=["","## Real original ARM64 counts and callsite PCs"]
for name,img in images.items():
    lines+=["","### "+name,
      "- SHA256: "+img["sha256"]+"; methods: "+str(img["objc_methods"])+
       "; ARM64 instructions: "+str(img["arm64_instructions"])]
    for k,x in img["xrefs"].items():
        lines.append("- "+k+": "+str(x["count"])+" references; PC "+
           ", ".join(y["pc"] for y in x["first8"]))
    for m in img["focused_methods"]:
        lines.append("- "+m["class"]+"."+m["selector"]+" IMP "+m["imp"]+
            "; instructions "+str(m["instructions"])+
            "; BL "+", ".join(x["callsite"]+"=>"+x["branch_to"] for x in m["bl"][:5]))
lines+=["","## Original Dashboard orientation hook instructions"]
for k,h in patches.items():
    lines+=["","### "+k+" ("+h["lo"]+".."+h["end"]+")","",
       "Instructions "+str(h["count"]),"~~~text"]
    lines.extend(x["pc"]+" "+x["asm"] for x in h["arm64"][:90])
    lines.append("~~~")
lines+=["","## Evidence boundaries",
"- Native12 Dashboard filter explicitly contains com.google.ios.youtube; static filter is not proof of injection running on user's iPhone.",
"- Distinguish main scene orientation policy, content-reference-size hooks and scene-settings host transaction; none alone proves renderer/player UIKit rotation accepted.",
"- Original Native12 fullscreen support and app-side role must be evaluated separately. Do not copy licensing, global private hooks, or arbitrary rotation/zoom.",
"- No runtime source patch or new DEB/Sileo/device pass in this scan."]
DOC.write_text("\n".join(lines)+"\n")
print("ORIGINAL_NATIVE12_SUMMARY_PASS",len(images),"images")
print("SAVED",OUT,OUT.stat().st_size)
print("SAVED",DOC,DOC.stat().st_size)
for k,x in images.items():
    print("ORIGINAL",k,"clientSettings",x["xrefs"]["app_orientation_feedback"]["count"],
          "UIKitGeometry",x["xrefs"]["ui_geometry"]["count"],
          "sceneHooks",x["xrefs"]["main_scene_hook"]["count"])
