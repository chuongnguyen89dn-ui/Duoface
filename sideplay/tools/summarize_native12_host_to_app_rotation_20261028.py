#!/usr/bin/env python3
"""Summarize exact Native12 original HOST->APP state and UIKit rotation machine
flow without reinterpreting SidePlay or copying proprietary code.
Source is SHA-pinned 7 MB original ARM64 audit, immutable on project GitHub.
"""
import hashlib,json,re
from pathlib import Path
ROOT=Path("sideplay/audit/native12-083-rotation-20261028")
SOURCE=ROOT/"NATIVE12_ORIGINAL_APP_ORIENTATION_HELPER_RUN_40648313067.json"
OUTPUT=ROOT/"NATIVE12_ORIGINAL_HOST_TO_APP_YOUTUBE_HANDSHAKE_20261028.json"
DOC=ROOT/"NATIVE12_ORIGINAL_HOST_TO_APP_YOUTUBE_HANDSHAKE_20261028.md"
EXPECTED_BLOB="2b80f8ff77247807f7eeba2fe24cae59c3e470b5"
EXPECTED_DEB="2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad"
EXPECTED_DYLIB="9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea"
def git_blob(raw):
    return hashlib.sha1(b"blob "+str(len(raw)).encode()+b"\0"+raw).hexdigest()
raw=SOURCE.read_bytes()
actual=git_blob(raw)
if actual!=EXPECTED_BLOB:raise RuntimeError("Original ARM64 report changed "+actual)
d=json.loads(raw)
assert d["original_deb_sha256"]==EXPECTED_DEB
assert d["dashboard_image_sha256"]==EXPECTED_DYLIB
# Prefix-based selector/string refs must be read with actual machine PCs.
TERMS=re.compile(r'orientation|state|State|bridge|Bridge|bundle|Bundle|width|height|Height|Width|'
  r'display|Display|token|Token|split|Split|notification|Notification|post|send|Send|'
  r'window|Window|scene|Scene|reflow|reconcile|layout|Layout|foreground|Foreground|'
  r'geometry|Geometry|screen|Screen|app|App|size|Size|setBounds|setFrame|'
  r'rotate|Rotate|supportedInterfaceOrientations|requestGeometryUpdate',re.I)
SKIP=re.compile(r'objc_(release|retain|autorelease)|stack_chk|exception|Unwind|dispatch_once',re.I)
CUT={"original_host_send_state_to_app":80,"original_host_notification_registration":85,
     "original_host_app_request_receiver":85,"original_host_state_change_notifier":70,
     "original_host_render_size_policy":65,"original_host_request_state_change":75,
     "app_state_check_on_process_start":80,"app_state_received_notification":100,
     "app_state_async_state_apply_block":60,"app_state_UIKit_reflow_dispatch":85,
     "app_state_first_attach":60,"app_state_reset_phone_mode":70,
     "app_state_initialization":70,"app_state_send_request":75}
names=list(CUT)
all_names=list(d["functions"])
result={"status":"ORIGINAL_NATIVE12_HOST_APP_YOUTUBE_ORIENTATION_HANDSHAKE_STATIC_ONLY",
    "source_immutable_git_blob":EXPECTED_BLOB,"source_sha256":hashlib.sha256(raw).hexdigest(),
    "original_deb_sha256":EXPECTED_DEB,"original_dashboard_sha256":EXPECTED_DYLIB,
    "original_filter":d["original_dashboard_filter"],"methods":{},
    "limits":["Source is original Native12, NOT SidePlay","No vendor code used in independent app",
              "Static xrefs and ARM64 instructions do not prove device rendering",
              "DuoFace .86 unchanged and Maps/Dock not touched"]}
for name in names:
    if name not in d["functions"]:continue
    x=d["functions"][name]
    body=x["original_arm64"]
    refs=x["annotated_selector_and_string_refs"]
    chosen=[{"pc":y["pc"],"asm":y["asm"]} for y in refs if TERMS.search(y["asm"])]
    # Selector annotated xrefs are more reliable than objdump callsite comment.
    # Include neighboring machine instructions for original argument provenance.
    blocks=[]
    for y in chosen[:CUT[name]]:
        pc=int(y["pc"],16)
        near=[z for z in body if abs(int(z["pc"],16)-pc)<=32]
        blocks.append({"ref_pc":y["pc"],"ref":y["asm"],
            "arm64_window":near})
    calls=x["direct_bl_edges"]
    important=[v for v in calls if v.get("direct_target_is_known_function_start") and not SKIP.search(v.get("target",""))][:55]
    result["methods"][name]={
        "exact_entry":x["actual_function_start"],"exact_end":x["actual_function_end"],
        "instructions_total":len(body),
        "objc_method":x["method"].get("objc_method") if x.get("method") else None,
        "all_semantic_refs":chosen[:CUT[name]],
        "ref_windows":blocks[:35],"direct_calls":important,
        "incoming":d.get("incoming_direct_callers",{}).get(name,[])[:10],
        "selection_truncated":len(chosen)>CUT[name]
    }
OUTPUT.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n")
lines=["# Native12 ORIGINAL Host ↔ YouTube application: scene orientation dataflow",
"",
"Original Native12 DEB: "+EXPECTED_DEB,
"Original Native12 Dashboard: "+EXPECTED_DYLIB,
"Raw original ARM64 run: https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40648313067",
"Raw immutable original Git blob: "+EXPECTED_BLOB,
"No SidePlay inference; no independent app changes.",
"","## ORIGINAL per-application filter", "",
json.dumps(result["original_filter"],ensure_ascii=False),
"","## Original exact function boundaries and value/selector references"]
for name,x in result["methods"].items():
    lines+=["", "### "+name+" "+x["exact_entry"]+".."+x["exact_end"],
         "Original ARM64 instructions: "+str(x["instructions_total"]),
         "Original ObjC owner: "+json.dumps(x["objc_method"],ensure_ascii=False)]
    for z in x["all_semantic_refs"]:
        lines.append("- "+z["pc"]+" "+z["asm"])
    for c in x["direct_calls"][:16]:
        lines.append("- BL "+c["pc"]+" -> "+c["target"]+
                     (" original callee="+json.dumps(c["direct_objc_callee"]) if c["direct_objc_callee"] else ""))
lines+=["","## Correctness scope",
"Original Native12 appStateListener handles its own per-app bridge state and orientation; any fix must maintain verified owner/timeout and leave .83 video lifecycle alone.",
"Original had private UIKit rotations and app-process injection; do not copy unsafe vendor hooks, licensing, global device rotation, or arbitrary zoom.",
"Unverified actual user iOS16 YouTube scene/client geometry: DO NOT assert fixed or package to Sileo from this report alone."]
DOC.write_text("\n".join(lines)+"\n")
assert "original_host_send_state_to_app" in result["methods"]
assert "app_state_received_notification" in result["methods"]
assert "app_state_UIKit_reflow_dispatch" in result["methods"]
print("NATIVE12_PROVEN_STATIC_ORIGINAL_HOST_TO_APP_HANDSHAKE",len(result["methods"]))
print("INPUT_GIT_BLOB_MATCH",EXPECTED_BLOB)
print("OUTPUT",OUTPUT,OUTPUT.stat().st_size)
print("READABLE",DOC,DOC.stat().st_size)
for name,item in result["methods"].items():
    print("ORIGINAL",name,item["exact_entry"],item["instructions_total"],"REFS",len(item["all_semantic_refs"]))
