#!/usr/bin/env python3
"""Decode Native12 original app-side UIKit scene orientation helper with exact
function starts. Original SHA-pinned binary only. No app runtime mutation.
"""
from __future__ import annotations
import argparse,bisect,hashlib,json,os,plistlib,re,subprocess,sys,tempfile
from pathlib import Path
PIN="2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad"
IMAGE_PIN="9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea"
INDEX_BLOB="efa45df59bc3c16887cc979bf3aedc0c93c92111"
MACHINE=re.compile(r"^\s*(?:0x)?([0-9a-fA-F]+):\s+(.+)$")
CALL=re.compile(r"\bbl\s+(0x[0-9a-fA-F]+)")
TARGETS={
    "app_scene_UIKit_orientation_reconciler":0x2ac688,
    "app_scene_orientation_predecessor":0x2ac50c,
    "app_scene_orientation_tail":0x2acc04,
    "app_scene_orientation_callback":0x2accbc,
    "app_state_received_notification":0x2ab98c,
    "app_state_initialization":0x2ab0a0,
    "app_state_send_request":0x2ab7a4,
    "app_state_active_notification":0x2ab948,
    "host_original_allowed_orientation_hook":0x2c8b4c,
    "host_original_reference_twoarg_hook":0x2c895c,
    "host_original_reference_threearg_hook":0x2c8a50,
}
def sha(a):return hashlib.sha256(a).hexdigest()
def git_blob(a):return hashlib.sha1(b"blob "+str(len(a)).encode()+b"\0"+a).hexdigest()
def main():
 p=argparse.ArgumentParser()
 p.add_argument("--deb",required=True,type=Path)
 p.add_argument("--index",required=True,type=Path)
 p.add_argument("--out",required=True,type=Path)
 args=p.parse_args()
 if sha(args.deb.read_bytes())!=PIN:raise RuntimeError("Source Native12 DEB is not SHA-pinned reference")
 blob=args.index.read_bytes()
 if git_blob(blob)!=INDEX_BLOB:raise RuntimeError("Original ABI index blob mismatch")
 idx=json.loads(blob)
 im=next(x for x in idx["native12"] if x["filename"]=="DuoFaceDashboard.dylib")
 starts=sorted(int(x,16) for x in im["lc_function_starts"])
 objc={int(x["imp"],16):x for x in im["objc_methods"]}
 with tempfile.TemporaryDirectory(prefix="original-native12-rotation-") as td:
  root=Path(td)/"payload"
  subprocess.run(["dpkg-deb","-x",str(args.deb),str(root)],check=True)
  orig=root/"var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib"
  if sha(orig.read_bytes())!=IMAGE_PIN:raise RuntimeError("Original Dashboard image mismatch")
  source_filter=plistlib.loads((orig.parent/"DuoFaceDashboard.plist").read_bytes())["Filter"]
  sys.path.insert(0,os.environ["NATIVE_PARSER_DIR"])
  from audit_native12_license_class_xrefs import select_arm64
  thin=select_arm64(orig.read_bytes())
  fname=Path(td)/"DuoFaceDashboard.arm64"
  fname.write_bytes(thin)
  cmd=[os.environ.get("OBJDUMP","llvm-objdump-18"),"--macho",
       "--disassemble","--no-show-raw-insn",str(fname)]
  v=subprocess.run(cmd,capture_output=True,text=True,encoding="utf-8",errors="replace")
  if v.returncode:raise RuntimeError("llvm-objdump failed "+v.stderr[-1300:])
  listing=[]
  for line in v.stdout.splitlines():
   m=MACHINE.match(line)
   if m:listing.append({"pc":int(m.group(1),16),"asm":m.group(2).strip()})
  if not listing:raise RuntimeError("missing real ARM64 assembly")
  def bounds(pc):
   k=bisect.bisect_right(starts,pc)-1
   if k<0 or k+1>=len(starts):raise RuntimeError("Original function interval missing "+hex(pc))
   return starts[k],starts[k+1]
  def owner(pc):
   try:
    lo,hi=bounds(pc)
   except RuntimeError:
    return {"function_start":None,"function_end":None,"objc_method":None,
            "status":"OUTSIDE_LC_FUNCTION_STARTS_OR_STUB_NOT_ASSIGNED"}
   m=objc.get(lo)
   return {"function_start":hex(lo),"function_end":hex(hi),
           "objc_method":({"class":m["class"],"selector":m["selector"],
                           "type":m["type"]} if m else None)}
  functions={}
  for name,pc in TARGETS.items():
   lo,hi=bounds(pc)
   body=[{"pc":hex(x["pc"]),"asm":x["asm"]} for x in listing if lo<=x["pc"]<hi]
   if not body or int(body[0]["pc"],16)!=lo:raise RuntimeError("exact original body start missing "+hex(lo))
   calls=[]
   for x in body:
    m=CALL.search(x["asm"])
    if m:
     dst=int(m.group(1),16)
     calls.append({"pc":x["pc"],"target":hex(dst),
                   "direct_target_is_known_function_start":dst in starts,
                   "direct_objc_callee":({"class":objc[dst]["class"],"selector":objc[dst]["selector"]} if dst in objc else None)})
   refs=[x for x in body if "Objc selector" in x["asm"] or "Objc cfstring" in x["asm"] or "literal pool for:" in x["asm"]]
   functions[name]={"source_pc":hex(pc),"actual_function_start":hex(lo),
                    "actual_function_end":hex(hi),
                    "method":owner(pc),"original_arm64":body,
                    "annotated_selector_and_string_refs":refs,
                    "direct_bl_edges":calls}
   print("NATIVE12_ACTUAL_FUNCTION",name,hex(lo),hex(hi),len(body),flush=True)
  # Find ACTUAL direct callers of private/UIKit orientation helper functions.
  incoming={}
  for name,target in TARGETS.items():
   pc=bounds(target)[0]
   selected=[]
   for x in listing:
    m=CALL.search(x["asm"])
    if not m or int(m.group(1),16)!=pc:continue
    at=x["pc"]
    ii=bisect.bisect_left([i["pc"] for i in listing],at)
    local=listing[max(0,ii-10):min(len(listing),ii+6)]
    selected.append({"callsite":hex(at),"caller":owner(at),
                     "arm64_window":[{"pc":hex(y["pc"]),"asm":y["asm"]} for y in local]})
   incoming[name]=selected[:50]
  result={"status":"NATIVE12_ORIGINAL_APP_SIDE_ORIENTATION_HELPER_EXACT_FUNCTION_BOUNDARIES",
          "original_deb_sha256":PIN,"dashboard_image_sha256":IMAGE_PIN,
          "thin_arm64_sha256":sha(thin),
          "method_index_git_blob":INDEX_BLOB,
          "original_dashboard_filter":source_filter,
          "total_machine_instructions":len(listing),
          "actual_function_starts":len(starts),
          "functions":functions,
          "incoming_direct_callers":incoming,
          "device_tested":False,
          "limits":["Exact function boundaries are original LC_FUNCTION_STARTS, not approximate ObjC nearest IMP",
                    "Static direct BL proven; dynamic ObjC messages and branch-to-runtime stubs are not exact receiver proofs",
                    "App UIKit process filter presence is not proof that YouTube rendered upright",
                    "No license code or vendor binary copied into independent DuoFace"]}
  args.out.parent.mkdir(parents=True,exist_ok=True)
  args.out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf8")
  print("NATIVE12_ORIGINAL_YOUTUBE_ROTATION_APP_SIDE_COMPLETE",args.out)
if __name__=="__main__":main()
